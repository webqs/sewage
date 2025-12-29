import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../login_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool uploading = false;

  Future<Map<String, dynamic>?> fetchProfile(String authId) async {
    return await Supabase.instance.client
        .from('profile')
        .select()
        .eq('auth_id', authId)
        .maybeSingle();
  }

  Future<void> uploadProfilePic() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile == null) return;

    setState(() => uploading = true);

    final file = File(pickedFile.path);
    final fileName = "avatar_${user.id}.jpg";

    try {
      await Supabase.instance.client.storage
          .from('profile')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      final publicUrl = Supabase.instance.client.storage
          .from('profile')
          .getPublicUrl(fileName);

      await Supabase.instance.client
          .from('profile')
          .update({'avatar_url': publicUrl})
          .eq('auth_id', user.id);

      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('Upload error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to upload image')));
      }
    }

    if (mounted) setState(() => uploading = false);
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
    );
  }
  void confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // close dialog
              await signOut();
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: confirmLogout, // ← changed
          ),
        ],

      ),
      body: user == null
          ? const Center(child: Text("No user logged in"))
          : FutureBuilder<Map<String, dynamic>?>(
        future: fetchProfile(user.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ---------- Avatar ----------
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: profile['avatar_url'] != null
                          ? NetworkImage(profile['avatar_url'])
                          : null,
                      child: profile['avatar_url'] == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.blue,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 18),
                        onPressed: uploading ? null : uploadProfilePic,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ---------- Info Card ----------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.1),
                        blurRadius: 6,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow("Name", profile['name']),
                      _infoRow("Email", profile['email']),
                      _infoRow("Role", profile['role']),
                      _infoRow("Contact", profile['contact']),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          Expanded(
            child: Text(value ?? "—",
                style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
