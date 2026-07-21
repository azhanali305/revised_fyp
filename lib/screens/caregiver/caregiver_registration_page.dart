import 'package:flutter/material.dart';
import 'package:fyp_revised/firebase_files/auth_service.dart';
import 'package:fyp_revised/screens/patient/patient_registration_page.dart';

class CaregiverRegistrationPage extends StatefulWidget {
 const CaregiverRegistrationPage({super.key});



  @override
  State<CaregiverRegistrationPage> createState() =>
      _CaregiverRegistrationPageState();
}

class _CaregiverRegistrationPageState
    extends State<CaregiverRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final AuthService authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  DateTime? _selectedDate;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      _selectedDate = picked;

      _dobController.text =
          "${picked.day}/${picked.month}/${picked.year}";
      setState(() {});
    }
  }

  bool _is18OrOlder(DateTime dob) {
    final today = DateTime.now();

    int age = today.year - dob.year;

    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }

    return age >= 18;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Caregiver Registration"),
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
                    labelText: "Full Name",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Enter your name" : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Enter email" : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Enter phone number" : null,
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

                    if (!_is18OrOlder(_selectedDate!)) {
                      return "Caregiver must be at least 18 years old";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value!.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        // TODO:
                        // 1. Firebase Authentication Sign Up
                        try{
                        await authService.signUp(
                        email: _emailController.text.trim(),
                        password: _passwordController.text.trim(),
                        );
                        }  
                        catch(e){
                        print(e);
                        }
                        // 2. Save caregiver profile to Firestore

                        // 3. Navigate to Patient Registration Page
                        Navigator.push(
                        context,
                        MaterialPageRoute(
                        builder: (context) => PatientRegistrationPage(),
                        ),
                    );
                    }},
                    child: const Text(
                      "Register",
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