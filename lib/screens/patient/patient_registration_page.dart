// Place this file at: lib/screens/patient/patient_registration_page.dart
//
// Your original file had no form (just a placeholder Text), so this is a
// new build, styled to match caregiver_registration_page.dart. It now also
// takes the caregiverId from the previous screen and saves the full patient
// record to Firestore ("patients" collection) in addition to the local
// Hive cache used for splash-screen routing.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:fyp_revised/models/patient_model.dart';
import 'package:fyp_revised/screens/patient/patient_dashboard.dart';

class PatientRegistrationPage extends StatefulWidget {
  final String caregiverId;

  const PatientRegistrationPage({super.key, required this.caregiverId});

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
      initialDate: DateTime(1950),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      _selectedDate = picked;
      _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      setState(() {});
    }
  }

  Future<void> _savePatientAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Firestore auto-generates the patientId here.
      final docRef = FirebaseFirestore.instance.collection('patients').doc();

      final patient = PatientModel(
        patientId: docRef.id,
        caregiverId: widget.caregiverId,
        fullName: _nameController.text.trim(),
        dateOfBirth: _selectedDate!,
        gender: _selectedGender,
        relationshipWithCaregiver: _relationshipController.text.trim(),
        preferredLanguage: _selectedLanguage,
        emergencyContactName: _emergencyNameController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim(),
        createdAt: DateTime.now(),
      );

      // Source of truth in Firestore.
      await docRef.set(patient.toMap());

      // Local cache so splash screen can route offline.
      final patientBox = Hive.box("patient");
      await patientBox.put("profile", patient.toMap());
      await patientBox.put("isSetupComplete", true);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PatientDashboard()),
        (route) => false,
      );
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
        title: const Text("Patient Registration"),
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
                  decoration: const InputDecoration(
                    labelText: "Patient Full Name",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Enter patient's name" : null,
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
                  decoration: const InputDecoration(
                    labelText: "Relationship with Caregiver",
                    hintText: "e.g. Son, Daughter, Spouse",
                    prefixIcon: Icon(Icons.family_restroom),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Enter the relationship" : null,
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
                  decoration: const InputDecoration(
                    labelText: "Emergency Contact Name",
                    prefixIcon: Icon(Icons.contact_emergency),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty
                      ? "Enter an emergency contact name"
                      : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _emergencyPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Emergency Contact Phone",
                    prefixIcon: Icon(Icons.phone_in_talk),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty
                      ? "Enter an emergency contact phone number"
                      : null,
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed:
                        _isSubmitting ? null : _savePatientAndContinue,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Save & Continue",
                            style: TextStyle(fontSize: 18),
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