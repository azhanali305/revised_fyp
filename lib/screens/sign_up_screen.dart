import "package:flutter/material.dart";
import "package:fyp_revised/firebase_files/auth_service.dart";
import "package:fyp_revised/screens/sign_in_screen.dart";

final _signUpFormKey = GlobalKey<FormState>();
final TextEditingController _emailController = TextEditingController();
final TextEditingController _passwordController = TextEditingController();

class SignUpScreen extends StatelessWidget {
  SignUpScreen({super.key});

  final AuthService authService = AuthService();
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 20),
        child: Form(
          key: _signUpFormKey,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                validator: (value) {
                if (value == null || value.isEmpty) {
                return "Email is required";
                }
                return null;
                },
                controller: _emailController,
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
                  if (_signUpFormKey.currentState!.validate()) {
                  try{
                  await authService.signUp(
                  email: _emailController.text.trim(),
                  password: _passwordController.text.trim(),
                  );
                  }  
                  catch(e){
                    print(e);
                  }
                  }
                },
                  child: Text("Sign Up")),
                ),
                SizedBox(
                  height: 20,
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignInScreen())),
                  child: Text("If you are signed Up: Log In"))
        
              ],
            )),
      ),
    );
  }
}