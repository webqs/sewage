import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _futureProfiles;

  @override
  void initState() {
    super.initState();
    _futureProfiles = fetchProfiles();
  }

  Future<List<Map<String, dynamic>>> fetchProfiles() async {
    final response = await supabase
        .from('profile')
        .select('id, role, email, created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> deleteProfile(int id) async {
    try {
      await supabase.from('profile').delete().eq('id', id);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile deleted")));

      setState(() {
        _futureProfiles = fetchProfiles();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Profile"),
        content: const Text("Are you sure you want to delete this profile?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              deleteProfile(id);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // FORCE WHITE BACKGROUND
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureProfiles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final profiles = snapshot.data ?? [];

          if (profiles.isEmpty) {
            return const Center(child: Text("No profiles found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              final int profileId = profile['id'];
              final String email = profile['email'] ?? "No email";

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 3,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueGrey.shade700,
                    child: Text(
                      profileId.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    email,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Role: ${profile['role'] ?? 'N/A'}"),
                      Text("Created: ${profile['created_at'] ?? 'N/A'}"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(profileId),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
