// admin_home_page.dart
import 'package:flutter/material.dart';
import 'package:wmsapp/appUI.dart';
// Assuming you'll create these pages
import 'package:wmsapp/manage_users.dart';
import 'package:wmsapp/manage_events.dart';
import 'package:wmsapp/appUI.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: AppTheme.mainOrange,
        scaffoldBackgroundColor: AppTheme.background,
      ),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppTheme.mainOrange,
          centerTitle: true,
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAdminOptionCard(
                context: context,
                title: 'Create and Manage Users',
                icon: Icons.group,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageUsersPage()),
                  );
                },
              ),
              // const SizedBox(height: 16),
              // _buildAdminOptionCard(
              //   context: context,
              //   title: 'Create and Manage Events/Sub-events',
              //   icon: Icons.event,
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => const ManageEventsPage()),
              //     );
              //   },
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminOptionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: AppTheme.mainOrange,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.headingStyle.copyWith(fontSize: 18),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}