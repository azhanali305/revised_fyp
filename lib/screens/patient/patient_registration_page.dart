// Place this file at: lib/screens/patient/patient_registration_page.dart
//
// Dual-purpose per the updated flow: Add Patient AND Edit Patient, both
// launched from the caregiver's Patient List screen.
//  - Add mode (existingPatient == null): creates a new Firestore doc +
//    local profile cache, and sets it as this device's active patient.
//  - Edit mode (existingPatient != null): form pre-filled, updates the
//    same Firestore doc + local profile cache, keeps the original
//    patientId/createdAt.
// Either way it pops back to the Patient List with `true` on success.
//
// Input restrictions (mirrors caregiver_registration_page.dart): name and
// relationship fields only accept letters/spaces, emergency contact phone
// only accepts digits and a leading '+'.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyp_revised/models/patient_model.dart';
import 'package:fyp_revised/services/patient_data_service.dart';

class PatientRegistrationPage extends StatefulWidget {
  final String caregiverId;
  final PatientModel? existingPatient;

  const PatientRegistrationPage({
    super.key,
    required this.caregiverId,
    this.existingPatient,
  });

  bool get isEditing => existingPatient != null;

  @override
  State<PatientRegistrationPage> createState() =>
      _PatientRegistrationPageState();
}

class _PatientRegistrationPageState extends State<PatientRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _relationshipController =
      TextEditingController();
  final TextEditingController _emergencyNameController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();

  DateTime? _selectedDate;
  String _selectedGender = "Male";
  String _selectedLanguage = "English";
  bool _isSubmitting = false;

  static final _lettersOnly = RegExp(r'[a-zA-Z ]');
  static final _lettersOnlyFull = RegExp(r'^[a-zA-Z ]+$');
  static final _phoneChars = RegExp(r'[0-9+]');
  static final _phoneFull = RegExp(r'^\+?[0-9]+$');

  @override
  void initState() {
    super.initState();
    final existing = widget.existingPatient;
    if (existing != null) {
      _nameController.text = existing.fullName;
      _selectedDate = existing.dateOfBirth;
      _dobController.text =
          "${existing.dateOfBirth.day}/${existing.dateOfBirth.month}/${existing.dateOfBirth.year}";
      _selectedGender = existing.gender;
      _relationshipController.text = existing.relationshipWithCaregiver;
      _selectedLanguage = existing.preferredLanguage;
      _emergencyNameController.text = existing.emergencyContactName;
      _emergencyPhoneController.text = existing.emergencyContactPhone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _relationshipController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1950),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      _selectedDate = picked;
      _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      setState(() {});
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final isEditing = widget.isEditing;
      final patientId = isEditing
          ? widget.existingPatient!.patientId
          : FirebaseFirestore.instance.collection('patients').doc().id;

      final patient = PatientModel(
        patientId: patientId,
        caregiverId: widget.caregiverId,
        fullName: _nameController.text.trim(),
        dateOfBirth: _selectedDate!,
        gender: _selectedGender,
        relationshipWithCaregiver: _relationshipController.text.trim(),
        preferredLanguage: _selectedLanguage,
        emergencyContactName: _emergencyNameController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim(),
        createdAt: isEditing ? widget.existingPatient!.createdAt : DateTime.now(),
      );

      // Source of truth in Firestore.
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .set(patient.toMap());

      // Local cache, per patientId.
      await PatientDataService.savePatientProfile(patient);

      if (!isEditing) {
        // A newly added patient becomes this device's active patient by
        // default; the caregiver can switch via the Patient List.
        await PatientDataService.setActivePatient(patientId);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not save patient: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? "Edit Patient" : "Add Patient"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  inputFormatters: [FilteringTextInputFormatter.allow(_lettersOnly)],
                  decoration: const InputDecoration(
                    labelText: "Patient Full Name",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Enter patient's name";
                    }
                    if (!_lettersOnlyFull.hasMatch(value)) {
                      return "Name can only contain letters";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: const InputDecoration(
                    labelText: "Date of Birth",
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_selectedDate == null) {
                      return "Select Date of Birth";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: "Gender",
                    prefixIcon: Icon(Icons.wc),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: "Male", child: Text("Male")),
                    DropdownMenuItem(value: "Female", child: Text("Female")),
                    DropdownMenuItem(value: "Other", child: Text("Other")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value ?? "Male";
                    });
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _relationshipController,
                  inputFormatters: [FilteringTextInputFormatter.allow(_lettersOnly)],
                  decoration: const InputDecoration(
                    labelText: "Relationship with Caregiver",
                    hintText: "e.g. Son, Daughter, Spouse",
                    prefixIcon: Icon(Icons.family_restroom),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Enter the relationship";
                    }
                    if (!_lettersOnlyFull.hasMatch(value)) {
                      return "Relationship can only contain letters";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: const InputDecoration(
                    labelText: "Preferred Language",
                    prefixIcon: Icon(Icons.language),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: "English", child: Text("English")),
                    DropdownMenuItem(value: "Urdu", child: Text("Urdu")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedLanguage = value ?? "English";
                    });
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _emergencyNameController,
                  inputFormatters: [FilteringTextInputFormatter.allow(_lettersOnly)],
                  decoration: const InputDecoration(
                    labelText: "Emergency Contact Name",
                    prefixIcon: Icon(Icons.contact_emergency),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Enter an emergency contact name";
                    }
                    if (!_lettersOnlyFull.hasMatch(value)) {
                      return "Name can only contain letters";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _emergencyPhoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.allow(_phoneChars)],
                  decoration: const InputDecoration(
                    labelText: "Emergency Contact Phone",
                    prefixIcon: Icon(Icons.phone_in_talk),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Enter an emergency contact phone number";
                    }
                    if (!_phoneFull.hasMatch(value)) {
                      return "Phone can only contain numbers and a leading +";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _savePatient,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.isEditing ? "Update Patient" : "Save Patient",
                            style: const TextStyle(fontSize: 18),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}