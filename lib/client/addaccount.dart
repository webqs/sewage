import 'package:flutter/material.dart';

import '../supabase_config.dart';

class AddAccount extends StatefulWidget {
  const AddAccount({super.key});

  @override
  State<AddAccount> createState() => _AddAccountState();
}

class _AddAccountState extends State<AddAccount> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final contactController = TextEditingController();

  bool loading = false;

  Future<void> createAccount() async {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        nameController.text.isEmpty ||
        contactController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => loading = true);

    try {
      final res = await SupabaseConfig.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (res.user == null) throw "Account creation failed";

      await SupabaseConfig.client.from('profile').insert({
        'auth_id': res.user!.id,
        'email': emailController.text.trim(),
        'name': nameController.text.trim(),
        'contact': contactController.text.trim(),
        'role': 'worker', // client can only add workers
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Worker account created successfully")),
      );

      Navigator.pop(context);
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(labelText: "Contact Number"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: loading ? null : createAccount,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Worker"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
