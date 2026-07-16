import "package:flutter/material.dart";
import "package:fyp_revised/firebase_files/auth_service.dart";
import "package:fyp_revised/screens/sign_up_screen.dart";

final _signInFormKey = GlobalKey<FormState>();
final TextEditingController _emailController = TextEditingController();
final TextEditingController _passwordController = TextEditingController();

class SignInScreen extends StatelessWidget {
  SignInScreen({super.key});

  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 20),
        child: Form(
          key: _signInFormKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                validator: (value) {
                if (value == null || value.isEmpty) {
                return "Email is required";
                }
                return null;
                },
                keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'example@gmail.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
  ),  
                ),
              SizedBox(
                height: 20,
              ),
              TextFormField(
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  controller: _passwordController,
                  obscureText: true,
                ),
              SizedBox(
                height: 20,
              ),
              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 45),
                child: ElevatedButton(
                onPressed: () async {
                  if (_signInFormKey.currentState!.validate()) {
                  await authService.signIn(
                  email: _emailController.text.trim(),
                  password: _passwordController.text.trim(),
                  );
                  }
                },
                child: Text("Log In")),
              ),
              SizedBox(
                height: 20,
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignUpScreen())),
                child: Text("If you are not signed Up: Sign up"))

            ],
          )
        ),
      ),
    );
  }
}