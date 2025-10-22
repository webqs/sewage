import 'package:flutter/material.dart';

import 'alerts_screen.dart';
import 'history_screen.dart';
import 'unit_info_screen.dart';

// This can now be a StatelessWidget as it no longer manages internal state.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Helper method to handle navigation to a new page
  void _navigateToPage(BuildContext context, Widget page, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // We build a new Scaffold for each page to give it a standard look
        // with an AppBar and a back button.
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
      backgroundColor: Colors.grey[100], // Softer background color
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. Title at the top of the column
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Text(
                'Sewer Monitor Dashboard',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            // 2. Navigation controls now in a Column
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: <Widget>[
                  // Each button now calls the _navigateToPage method on tap
                  _buildNavButton(
                    icon: Icons.warning_amber_rounded,
                    label: 'Alerts',
                    onTap: () => _navigateToPage(
                      context,
                      const AlertsScreen(),
                      'Alerts',
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ), // Vertical spacing between buttons
                  _buildNavButton(
                    icon: Icons.info_outline,
                    label: 'Unit Info',
                    onTap: () => _navigateToPage(
                      context,
                      const UnitInfoScreen(),
                      'Unit Info',
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ), // Vertical spacing between buttons
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
            const SizedBox(height: 20),
            // The content area is no longer needed here.
          ],
        ),
      ),
    );
  }

  // Helper widget to build each navigation button for the new column layout.
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
        // A Row is used inside to place the icon and text side-by-side.
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
