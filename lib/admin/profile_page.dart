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

  String selectedRole = "All";
  late Future<List<Map<String, dynamic>>> _futureProfiles;

  final List<String> roles = ["All", "admin", "supervisor", "worker"];

  @override
  void initState() {
    super.initState();
    _futureProfiles = fetchProfiles();
  }

  Future<List<Map<String, dynamic>>> fetchProfiles() async {
    final query = supabase
        .from('profile')
        .select('id, role, email, created_at');

    final response = selectedRole == "All"
        ? await query.order('created_at', ascending: false)
        : await query
              .eq('role', selectedRole)
              .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _refresh() async {
    setState(() {
      _futureProfiles = fetchProfiles();
    });
  }

  Future<void> deleteProfile(int id) async {
    await supabase.from('profile').delete().eq('id', id);
    _refresh();
  }

  Future<void> updateRole(int id, String newRole) async {
    await supabase.from('profile').update({'role': newRole}).eq('id', id);

    _refresh();
  }

  void _showEditDialog(int id, String currentRole) {
    String tempRole = currentRole;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Edit Role",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: currentRole,
                items: roles
                    .where((r) => r != "All")
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (value) {
                  tempRole = value!;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  updateRole(id, tempRole);
                },
                child: const Text("Save"),
              ),
            ],
          ),
        );
      },
    );
  }

  String formatDate(String? date) {
    if (date == null) return "N/A";
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return "N/A";
    return DateFormat("dd MMM yyyy • hh:mm a").format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(""),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedRole,
              items: roles
                  .map(
                    (role) => DropdownMenuItem(value: role, child: Text(role)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedRole = value!;
                  _futureProfiles = fetchProfiles();
                });
              },
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureProfiles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profiles = snapshot.data ?? [];

          if (profiles.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueGrey,
                      child: Text(
                        profile['email'][0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      profile['email'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Role: ${profile['role']}"),
                        Text("Created: ${formatDate(profile['created_at'])}"),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () =>
                              _showEditDialog(profile['id'], profile['role']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteProfile(profile['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
