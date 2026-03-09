import 'package:flutter/material.dart';
import 'package:sewage/client/addaccount.dart';
import 'package:sewage/client/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Profie.dart';
import 'alerts_screen.dart';
import 'assign_task_screen.dart';
import 'device_map_screen.dart';
import 'history_screen.dart';
import 'performance_review_page.dart';
import 'unit_info_screen.dart';
import 'view_reports_page.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<ClientHomeScreen> {
  String? name;
  String? avatarUrl;
  bool loadingProfile = true;

  int totalAlerts = 0;
  int pendingAlerts = 0;
  int resolvedAlerts = 0;
  int totalWorkers = 0;
  double avgRating = 0;

  @override
  void initState() {
    super.initState();
    fetchProfile();
    loadAnalytics();
  }

  Future<void> fetchProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('profile')
        .select('name, avatar_url')
        .eq('auth_id', user.id)
        .maybeSingle();

    setState(() {
      name = response?['name'];
      avatarUrl = response?['avatar_url'];
      loadingProfile = false;
    });
  }

  Future<void> loadAnalytics() async {
    final alertsRes = await Supabase.instance.client.from('alerts').select();
    final workersRes = await Supabase.instance.client
        .from('profile')
        .select()
        .eq('role', 'worker');
    final reviewsRes = await Supabase.instance.client
        .from('performance_reviews')
        .select();

    final total = alertsRes.length;
    final pending = alertsRes.where((a) => a['processed'] == false).length;
    final resolved = alertsRes.where((a) => a['processed'] == true).length;

    double avg = 0;
    if (reviewsRes.isNotEmpty) {
      avg =
          reviewsRes.map((r) => r['rating'] as int).reduce((a, b) => a + b) /
          reviewsRes.length;
    }

    setState(() {
      totalAlerts = total;
      pendingAlerts = pending;
      resolvedAlerts = resolved;
      totalWorkers = workersRes.length;
      avgRating = avg;
    });
  }

  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final displayName = name ?? "User";

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(displayName),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F6F9),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDashboard(),
                      const SizedBox(height: 20),
                      _quickActions(),
                      const SizedBox(height: 20),
                      Expanded(child: _buildGrid()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader(String displayName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome Back 👋",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ).then((_) => fetchProfile());
            },
            child: CircleAvatar(
              radius: 22,
              backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null || avatarUrl!.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // ================= DASHBOARD =================

  Widget _buildDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Dashboard Overview",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _statCard("Total Alerts", totalAlerts, Icons.warning, Colors.blue),
            _statCard("Pending", pendingAlerts, Icons.error_outline, Colors.orange),
            _statCard("Resolved", resolvedAlerts, Icons.check_circle, Colors.green),
            _statCard("Workers", totalWorkers, Icons.people, Colors.purple),
          ],
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 6),
            Text(
              "Average Worker Rating: ${avgRating.toStringAsFixed(1)} / 5",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String title, int value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(title, style: const TextStyle(fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
  Widget _quickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.assignment),
                label: const Text("Assign Task"),
                onPressed: () =>
                    _navigateToPage(context, const AssignTaskScreen()),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.description),
                label: const Text("View Reports"),
                onPressed: () =>
                    _navigateToPage(context, const ViewReportsPage()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= NAV GRID =================

  Widget _buildGrid() {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 0.9,
      children: [
        _navCard(
          Icons.warning,
          "Alerts",
          () => _navigateToPage(context, const AlertsScreen()),
        ),
        _navCard(
          Icons.history,
          "History",
          () => _navigateToPage(context, const HistoryScreen()),
        ),
        _navCard(
          Icons.map,
          "Map",
          () => _navigateToPage(context, const DeviceMapScreen()),
        ),
        _navCard(
          Icons.assignment,
          "Assign",
          () => _navigateToPage(context, const AssignTaskScreen()),
        ),
        _navCard(
          Icons.bar_chart,
          "Performance",
          () => _navigateToPage(context, const PerformanceReviewPage()),
        ),
        _navCard(
          Icons.people,
          "Users",
          () => _navigateToPage(context, const ProfilePage()),
        ),
        _navCard(
          Icons.person_add,
          "Add Account",
          () => _navigateToPage(context, const AddAccount()),
        ),
        _navCard(
          Icons.description,
          "Reports",
          () => _navigateToPage(context, const ViewReportsPage()),
        ),
        _navCard(
          Icons.info,
          "Unit Info",
          () => _navigateToPage(context, const UnitInfoScreen()),
        ),
      ],
    );
  }

  Widget _navCard(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.blueAccent),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
