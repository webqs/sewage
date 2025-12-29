import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  // 🔹 Only fetch WORKERS + avatar
  Future<List<Map<String, dynamic>>> fetchProfiles() async {
    final response = await supabase
        .from('profile')
        .select('id, role, email, created_at, avatar_url')
        .eq('role', 'worker')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  String formatDate(String? raw) {
    if (raw == null) return "Unknown";
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat("MMM d, yyyy  h:mm a").format(dt.toLocal());
  }

  Future<void> deleteProfile(int id) async {
    await supabase.from('profile').delete().eq('id', id);
    setState(() => _futureProfiles = fetchProfiles());

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Worker removed")));
  }

  void _confirmDelete(int id, String email) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Remove Worker"),
        content: Text("Remove this worker account?\n$email"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              deleteProfile(id);
            },
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
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
          return const Center(child: Text("No workers found."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final profile = profiles[index];

            final id = profile['id'];
            final email = profile['email'] ?? 'Unknown';
            final avatar = profile['avatar_url'];
            final createdAt = formatDate(profile['created_at']);

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // 🧑 Avatar
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.blueGrey.shade300,
                      backgroundImage:
                      (avatar != null && avatar.isNotEmpty) ? NetworkImage(avatar) : null,
                      child: (avatar == null || avatar.isEmpty)
                          ? Text(
                        email[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      )
                          : null,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(email,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text("Joined: $createdAt",
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(id, email),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
