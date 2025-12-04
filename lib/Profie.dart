import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool uploading = false;

  /// ✅ FETCH PROFILE USING auth_id (MATCHES YOUR TABLE)
  Future<Map<String, dynamic>?> fetchProfile(String authId) async {
    return await Supabase.instance.client
        .from('profile')
        .select()
        .eq('auth_id', authId)
        .maybeSingle();
  }

  /// ✅ UPLOAD IMAGE + UPDATE PROFILE
  Future<void> uploadProfilePic() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final pickedFile =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

    if (pickedFile == null) return;

    setState(() => uploading = true);

    final file = File(pickedFile.path);
    final fileName = "avatar_${user.id}.jpg";

    try {
      /// ✅ CORRECT BUCKET NAME
      await Supabase.instance.client.storage
          .from('profile')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      final publicUrl = Supabase.instance.client.storage
          .from('profile')
          .getPublicUrl(fileName);

      /// ✅ UPDATE USING auth_id (NOT id, NOT email)
      await Supabase.instance.client.from('profile').update({
        'avatar_url': publicUrl,
      }).eq('auth_id', user.id);

      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('Upload error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
      }
    }

    if (mounted) setState(() => uploading = false);
  }

  Future<void> signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
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
        body: const Center(child: Text('No user logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => signOut(context),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchProfile(user.id), // ✅ auth_id match
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Profile not found"));
          }

          final profile = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // -------------------------
                // ✅ Profile Picture
                // -------------------------
                CircleAvatar(
                  radius: 60,
                  backgroundImage: profile['avatar_url'] != null
                      ? NetworkImage(profile['avatar_url'])
                      : null,
                  child: profile['avatar_url'] == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),

                const SizedBox(height: 12),

                uploading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text("Upload Profile Picture"),
                  onPressed: uploadProfilePic,
                ),

                const SizedBox(height: 30),

                // -------------------------
                // ✅ Email & Role Details
                // -------------------------
                Text(
                  'Email: ${profile['email'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Role: ${profile['role'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
