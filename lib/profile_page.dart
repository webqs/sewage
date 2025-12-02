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

  Future<List<Map<String, dynamic>>> fetchProfiles() async {
    final response = await supabase.from('profile').select();
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  void initState() {
    super.initState();
    _futureProfiles = fetchProfiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profiles"),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      body: FutureBuilder(
        future: _futureProfiles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          final profiles = snapshot.data ?? [];

          if (profiles.isEmpty) {
            return const Center(
              child: Text("No profiles found."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 3,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueGrey.shade700,
                    child: Text(
                      profile['id'].toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    "Role: ${profile['role'] ?? 'N/A'}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Created: ${profile['created_at'] ?? 'N/A'}",
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
