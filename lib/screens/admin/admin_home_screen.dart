import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../widgets/user_profile_header.dart';
import '../auth/login_screen.dart';
import 'admin_alerts_screen.dart';
import 'analytics_screen.dart';
import 'user_management_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final AuthService authService = AuthService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: authService.getUserData(authService.currentUser!.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        UserModel user = snapshot.data!;

        List<Widget> _screens = [
          _buildDashboard(),
          UserManagementScreen(),
          AnalyticsScreen(),
        ];

        return Scaffold(
          body: Column(
            children: [
              UserProfileHeader(user: user),
              Expanded(child: _screens[_selectedIndex]),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() => _selectedIndex = index);
            },
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Users',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics),
                label: 'Analytics',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('alerts').snapshots(),
          builder: (context, alertSnapshot) {
            if (!userSnapshot.hasData || !alertSnapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            int totalUsers = userSnapshot.data!.docs.length;
            int totalStudents = userSnapshot.data!.docs
                .where((doc) => (doc.data() as Map)['role'] == 'student')
                .length;
            int totalSecurity = userSnapshot.data!.docs
                .where((doc) => (doc.data() as Map)['role'] == 'security')
                .length;
            int totalAlerts = alertSnapshot.data!.docs.length;
            int pendingAlerts = alertSnapshot.data!.docs
                .where((doc) => (doc.data() as Map)['status'] == 'pending')
                .length;

            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Overview',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  
                  // Stats Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildStatCard('Total Users', totalUsers.toString(), Colors.blue, Icons.people),
                      _buildStatCard('Students', totalStudents.toString(), Colors.green, Icons.school),
                      _buildStatCard('Security', totalSecurity.toString(), Colors.orange, Icons.security),
                      _buildStatCard('Total Alerts', totalAlerts.toString(), Colors.red, Icons.notifications),
                      _buildStatCard('Pending', pendingAlerts.toString(), Colors.red, Icons.warning),
                      _buildStatCard('System Status', 'Active', Colors.green, Icons.check_circle),
                    ],
                  ),
                  
                  SizedBox(height: 24),
                  
                  Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  
                  _buildQuickAction(
                    'View All Alerts',
                    'Monitor emergency alerts',
                    Icons.notifications_active,
                    Colors.red,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AdminAlertsScreen()),
                      );
                    },
                  ),
                  SizedBox(height: 12),
                  _buildQuickAction(
                    'Manage Users',
                    'Add, edit or remove users',
                    Icons.person_add,
                    Colors.blue,
                    () {
                      setState(() => _selectedIndex = 1);
                    },
                  ),
                  SizedBox(height: 12),
                  _buildQuickAction(
                    'View Analytics',
                    'Response times and statistics',
                    Icons.analytics,
                    Colors.purple,
                    () {
                      setState(() => _selectedIndex = 2);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
            ),
            SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}