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

  int alertCount = 0;
  int reportCount = 0;
  double avgRating = 0;

  Future<Map<String, dynamic>?> fetchProfile(String authId) async {
    return await Supabase.instance.client
        .from('profile')
        .select()
        .eq('auth_id', authId)
        .maybeSingle();
  }

  Future<void> loadStats(String authId) async {
    final alerts = await Supabase.instance.client
        .from('alerts')
        .select()
        .eq('assigned_worker_id', authId);

    final reports = await Supabase.instance.client
        .from('report')
        .select();

    final reviews = await Supabase.instance.client
        .from('performance_reviews')
        .select()
        .eq('worker_id', authId);

    double rating = 0;
    if (reviews.isNotEmpty) {
      rating = reviews
          .map((r) => r['rating'] as int)
          .reduce((a, b) => a + b) /
          reviews.length;
    }

    if (!mounted) return;

    setState(() {
      alertCount = alerts.length;
      reportCount = reports.length;
      avgRating = rating;
    });
  }

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
      await Supabase.instance.client.storage
          .from('profile')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      final publicUrl = Supabase.instance.client.storage
          .from('profile')
          .getPublicUrl(fileName);

      await Supabase.instance.client
          .from('profile')
          .update({'avatar_url': publicUrl}).eq('auth_id', user.id);

      if (mounted) setState(() {});
    } catch (error) {
      debugPrint(error.toString());
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
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout"),
            onPressed: () async {
              Navigator.pop(context);
              await signOut();
            },
          )
        ],
      ),
    );
  }

  Color roleColor(String role) {
    switch (role) {
      case "admin":
        return Colors.purple;
      case "worker":
        return Colors.green;
      case "client":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: confirmLogout)
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

          loadStats(user.id);

          final role = profile['role'] ?? "user";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ================= PROFILE HEADER =================

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

                const SizedBox(height: 16),

                Text(
                  profile['name'] ?? "",
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor(role),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),

                const SizedBox(height: 24),

                // ================= ACCOUNT INFO =================

                _card(
                  title: "Account Information",
                  children: [
                    _infoRow("Email", profile['email']),
                    _infoRow("Contact", profile['contact']),
                    _infoRow("Location", profile['location']),
                  ],
                ),

                const SizedBox(height: 20),

                // ================= ACTIVITY =================

                _card(
                  title: "Activity Summary",
                  children: [
                    _infoRow("Alerts Assigned", alertCount.toString()),
                    _infoRow("Reports", reportCount.toString()),
                    _infoRow(
                        "Average Rating", avgRating.toStringAsFixed(1)),
                  ],
                ),

                const SizedBox(height: 30),

                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  onPressed: confirmLogout,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...children
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value ?? "—")),
        ],
      ),
    );
  }
}