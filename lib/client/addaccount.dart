import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sewage/worker/workerhome.dart';

import '../supabase_config.dart'; // notifications

class addaccounnt extends StatefulWidget {
  const addaccounnt({super.key});

  @override
  State<addaccounnt> createState() => _AddAccountState();
}

class _AddAccountState extends State<addaccounnt> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String selectedRole = "Client"; // default
  bool loading = false;

  Future<void> createAccount() async {
    setState(() => loading = true);

    try {
      // 1️⃣ Create authentication account
      final res = await SupabaseConfig.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (res.user == null) {
        throw "Failed to create auth user";
      }

      final authId = res.user!.id; // UUID
      final email = emailController.text.trim();

      // 2️⃣ Insert into profile table (int8 id auto-increments)
      await SupabaseConfig.client.from('profile').insert({
        'auth_id': authId, // store UUID here
        'email': email,
        'role': selectedRole.toLowerCase(),
      });

      // 3️⃣ Success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Account created as $selectedRole")),
      );

      // 4️⃣ Navigate home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WorkerHomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  "Create Account",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                // Email
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Password
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Role Selector
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelText: "Select Role",
                  ),
                  items: const [
                    DropdownMenuItem(value: "Client", child: Text("Client")),
                    DropdownMenuItem(value: "Worker", child: Text("Worker")),
                  ],
                  onChanged: (value) {
                    setState(() => selectedRole = value!);
                  },
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: loading ? null : createAccount,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Create Account"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
