import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/alert_model.dart';
import '../common/map_view_screen.dart';

class AdminAlertsScreen extends StatefulWidget {
  @override
  State<AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<AdminAlertsScreen> {
  String selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Alerts'),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          // Filter buttons
          Container(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  buildFilterChip('all', 'All', Colors.grey),
                  SizedBox(width: 8),
                  buildFilterChip('pending', 'Pending', Colors.red),
                  SizedBox(width: 8),
                  buildFilterChip('acknowledged', 'Acknowledged', Colors.orange),
                  SizedBox(width: 8),
                  buildFilterChip('resolved', 'Resolved', Colors.green),
                ],
              ),
            ),
          ),

          // Alerts list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getFilteredStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          selectedFilter == 'all'
                              ? 'No alerts found'
                              : 'No ${selectedFilter} alerts',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    AlertModel alert = AlertModel.fromMap(doc.data() as Map<String, dynamic>);
                    return buildAlertCard(context, alert);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFilterChip(String filter, String label, Color color) {
    bool isSelected = selectedFilter == filter;

    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: Colors.grey[200],
      selectedColor: color,
      onSelected: (selected) {
        setState(() {
          selectedFilter = filter;
        });
      },
      avatar: isSelected ? Icon(Icons.check, color: Colors.white, size: 18) : null,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Stream<QuerySnapshot> getFilteredStream() {
    if (selectedFilter == 'all') {
      return FirebaseFirestore.instance
          .collection('alerts')
          .orderBy('timestamp', descending: true)
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('alerts')
          .where('status', isEqualTo: selectedFilter)
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
  }

  Widget buildAlertCard(BuildContext context, AlertModel alert) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (alert.status) {
      case 'pending':
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        statusText = 'PENDING';
        break;
      case 'acknowledged':
        statusColor = Colors.orange;
        statusIcon = Icons.visibility;
        statusText = 'ACKNOWLEDGED';
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'RESOLVED';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'UNKNOWN';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => showAlertDetails(context, alert),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 28),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.studentName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          alert.type,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy - hh:mm a').format(alert.timestamp),
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${alert.latitude.toStringAsFixed(4)}, ${alert.longitude.toStringAsFixed(4)}',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (alert.description.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  alert.description,
                  style: TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void showAlertDetails(BuildContext context, AlertModel alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Alert Details',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),

                detailRow('Student', alert.studentName),
                detailRow('Type', alert.type),
                detailRow('Status', alert.status.toUpperCase()),
                detailRow('Time', DateFormat('MMM dd, yyyy - hh:mm a').format(alert.timestamp)),
                detailRow('Location', '${alert.latitude.toStringAsFixed(6)}, ${alert.longitude.toStringAsFixed(6)}'),
                if (alert.description.isNotEmpty) detailRow('Description', alert.description),

                SizedBox(height: 20),

                // Map button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.map),
                    label: Text('View Location on Map'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.blue, width: 2),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapViewScreen(
                            latitude: alert.latitude,
                            longitude: alert.longitude,
                            title: '${alert.type} - ${alert.studentName}',
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 24),

                // Admin actions
                Text(
                  'Admin Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),

                // Delete button (for resolved alerts)
                if (alert.status == 'resolved') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        bool? confirmDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete Alert'),
                            content: Text('Are you sure you want to permanently delete this alert? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: Text('Delete', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );

                        if (confirmDelete == true) {
                          await FirebaseFirestore.instance
                              .collection('alerts')
                              .doc(alert.alertId)
                              .delete();
                          
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Alert deleted successfully'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.delete, color: Colors.white),
                      label: Text('Delete Alert', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],

                // Status update buttons (for pending/acknowledged)
                if (alert.status == 'pending') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('alerts')
                                .doc(alert.alertId)
                                .update({'status': 'acknowledged'});
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Alert acknowledged'), backgroundColor: Colors.orange),
                            );
                          },
                          icon: Icon(Icons.visibility, color: Colors.white),
                          label: Text('Acknowledge', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('alerts')
                                .doc(alert.alertId)
                                .update({'status': 'resolved'});
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Alert resolved'), backgroundColor: Colors.green),
                            );
                          },
                          icon: Icon(Icons.check_circle, color: Colors.white),
                          label: Text('Resolve', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (alert.status == 'acknowledged') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('alerts')
                            .doc(alert.alertId)
                            .update({'status': 'resolved'});
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Alert resolved'), backgroundColor: Colors.green),
                        );
                      },
                      icon: Icon(Icons.check_circle, color: Colors.white),
                      label: Text('Mark as Resolved', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}