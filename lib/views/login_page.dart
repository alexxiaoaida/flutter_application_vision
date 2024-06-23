import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_page.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  LoginPage({super.key});

Future<void> login(BuildContext context) async {
  if (!_formKey.currentState!.validate()) {
    return;
  }
  final email = emailController.text;
  final password = passwordController.text;
  try {
    UserCredential userCredential = await signInWithEmailAndPassword(email, password);
    handleLoginSuccess(context, userCredential);
  } on FirebaseAuthException {
    showLoginFailedDialog(context);
  }
}

Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
  return await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
}

void handleLoginSuccess(BuildContext context, UserCredential userCredential) {
  const adminEmail = 'admin@example.com';

  if (userCredential.user?.email == adminEmail) {
    Get.to(() => AdminPage());
  } else {
    _showUnauthorizedAccessSnackBar(context);
  }
}

void _showUnauthorizedAccessSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Unauthorized access')),
  );
}

void showLoginFailedDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Login Failed'),
      content: const Text('Incorrect email or password. Please try again.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Login'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Get.back();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                onChanged: (value) {
                  _formKey.currentState?.validate();
                },
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                onChanged: (value) {
                  _formKey.currentState?.validate();
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => login(context),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
