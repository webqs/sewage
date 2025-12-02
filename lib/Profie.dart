import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_page.dart'; // make sure to import your LoginPage file

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Fetch profile using the currently logged-in user's email
  Future<Map<String, dynamic>?> fetchProfileByEmail(String email) async {
    final profile = await Supabase.instance.client
        .from('profile')
        .select('email, role')
        .eq('email', email)
        .maybeSingle(); // returns null if not found
    return profile;
  }

  // Logout function
  Future<void> signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    // Navigate to LoginPage and remove all previous routes
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(child: Text('No user logged in.')),
      );
    }

    final email = user.email!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => signOut(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchProfileByEmail(email),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No profile found.'));
          }

          final profile = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email: ${profile['email']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Role: ${profile['role']}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
