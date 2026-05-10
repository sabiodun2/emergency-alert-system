import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/alert_model.dart';

class AnalyticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics Dashboard'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('alerts').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          List<AlertModel> alerts = snapshot.data!.docs
              .map((doc) => AlertModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

          int totalAlerts = alerts.length;
          int pendingAlerts = alerts.where((a) => a.status == 'pending').length;
          int acknowledgedAlerts = alerts.where((a) => a.status == 'acknowledged').length;
          int resolvedAlerts = alerts.where((a) => a.status == 'resolved').length;

          // Calculate average response time
          List<AlertModel> resolvedList = alerts.where((a) => a.status == 'resolved').toList();
          double avgResponseTime = 0;
          if (resolvedList.isNotEmpty) {
            // This is simplified - you'd need to track acknowledgment time
            avgResponseTime = 15.5; // Mock data in minutes
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Cards
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Total Alerts', totalAlerts.toString(), Colors.blue, Icons.notifications)),
                    SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Pending', pendingAlerts.toString(), Colors.red, Icons.warning)),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Acknowledged', acknowledgedAlerts.toString(), Colors.orange, Icons.visibility)),
                    SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Resolved', resolvedAlerts.toString(), Colors.green, Icons.check_circle)),
                  ],
                ),
                SizedBox(height: 12),
                _buildStatCard('Avg Response Time', '${avgResponseTime.toStringAsFixed(1)} min', Colors.purple, Icons.timer),
                
                SizedBox(height: 24),
                
                // Pie Chart
                Text('Alert Status Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Container(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: pendingAlerts.toDouble(),
                          title: 'Pending\n$pendingAlerts',
                          color: Colors.red,
                          radius: 100,
                          titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        PieChartSectionData(
                          value: acknowledgedAlerts.toDouble(),
                          title: 'Ack.\n$acknowledgedAlerts',
                          color: Colors.orange,
                          radius: 100,
                          titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        PieChartSectionData(
                          value: resolvedAlerts.toDouble(),
                          title: 'Resolved\n$resolvedAlerts',
                          color: Colors.green,
                          radius: 100,
                          titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Alert Types
                Text('Alert Types Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                ...(_buildAlertTypeBreakdown(alerts)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAlertTypeBreakdown(List<AlertModel> alerts) {
    Map<String, int> typeCounts = {};
    for (var alert in alerts) {
      typeCounts[alert.type] = (typeCounts[alert.type] ?? 0) + 1;
    }

    return typeCounts.entries.map((entry) {
      return Card(
        margin: EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(Icons.label, color: Colors.blue),
          title: Text(entry.key),
          trailing: Chip(
            label: Text(entry.value.toString()),
            backgroundColor: Colors.blue,
            labelStyle: TextStyle(color: Colors.white),
          ),
        ),
      );
    }).toList();
  }
}