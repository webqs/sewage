import 'package:flutter/material.dart';

import 'Profie.dart';
import 'alerts_screen.dart';
import 'history_screen.dart';
import 'unit_info_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigateToPage(BuildContext context, Widget page, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Colors.grey[100],
            elevation: 0,
            foregroundColor: Colors.black87,
          ),
          body: page,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // 🔥 App Bar (Corrected)
      appBar: AppBar(
        title: const Text(
          'Sewer Monitor Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),

      // 🔥 Body starts here (NO semicolon above!)
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 12),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _buildNavButton(
                      icon: Icons.warning_amber_rounded,
                      label: 'Alerts',
                      onTap: () => _navigateToPage(
                        context,
                        const AlertsScreen(),
                        'Alerts',
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildNavButton(
                      icon: Icons.info_outline,
                      label: 'Unit Info',
                      onTap: () => _navigateToPage(
                        context,
                        const UnitInfoScreen(),
                        'Unit Info',
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildNavButton(
                      icon: Icons.history,
                      label: 'Action & History',
                      onTap: () => _navigateToPage(
                        context,
                        const HistoryScreen(),
                        'Action & History',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final color = Colors.grey.shade700;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}