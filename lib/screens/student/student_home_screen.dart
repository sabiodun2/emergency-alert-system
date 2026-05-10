import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/alert_model.dart';
import '../../models/user_model.dart';
import '../../widgets/user_profile_header.dart';
import '../common/map_view_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final AuthService authService = AuthService();
  final DatabaseService databaseService = DatabaseService();
  bool isLoading = false;

  Future<void> sendQuickEmergencyAlert() async {
    setState(() => isLoading = true);

    try {
      UserModel? user = await authService.getUserData(authService.currentUser!.uid);
      if (user == null) throw Exception('User not found');

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      Position position = await Geolocator.getCurrentPosition();

      String alertId = DateTime.now().millisecondsSinceEpoch.toString();
      
      AlertModel alert = AlertModel(
        alertId: alertId,
        studentId: user.uid,
        studentName: user.name,
        type: 'EMERGENCY',
        description: 'Emergency alert - requires urgent attention!',
        latitude: position.latitude,
        longitude: position.longitude,
        status: 'pending',
        timestamp: DateTime.now(),
      );

      await databaseService.sendAlert(alert);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🚨 Emergency alert sent!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showCustomAlertDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomAlertDialog(
        authService: authService,
        databaseService: databaseService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: authService.getUserData(authService.currentUser!.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        UserModel user = snapshot.data!;

        return Scaffold(
          body: Column(
            children: [
              UserProfileHeader(user: user),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Quick emergency button
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24),
                        child: Column(
                          children: [
                            ElevatedButton(
                              onPressed: isLoading ? null : sendQuickEmergencyAlert,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.symmetric(vertical: 30),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                              ),
                              child: isLoading
                                  ? CircularProgressIndicator(color: Colors.white)
                                  : Column(
                                      children: [
                                        Icon(Icons.emergency, size: 60, color: Colors.white),
                                        SizedBox(height: 12),
                                        Text(
                                          'CLICK TO ALERT',
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Tap for immediate help',
                                          style: TextStyle(fontSize: 14, color: Colors.white70),
                                        ),
                                      ],
                                    ),
                            ),
                            
                            SizedBox(height: 16),
                            
                            OutlinedButton(
                              onPressed: showCustomAlertDialog,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.blue, width: 2),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    'Create Custom Alert',
                                    style: TextStyle(
                                      fontSize: 16,
                                      // color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Divider(),

                      // Alert history header
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.history, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              'My Alerts',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      // Alerts list
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('alerts')
                            .where('studentId', isEqualTo: authService.currentUser!.uid)
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Padding(
                              padding: EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(Icons.check_circle_outline, size: 60, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text('No alerts sent yet', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              var doc = snapshot.data!.docs[index];
                              AlertModel alert = AlertModel.fromMap(doc.data() as Map<String, dynamic>);
                              
                              return _buildAlertCard(alert);
                            },
                          );
                        },
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertCard(AlertModel alert) {
    Color statusColor = alert.status == 'pending' 
        ? Colors.red 
        : alert.status == 'acknowledged' 
            ? Colors.orange 
            : Colors.green;

    IconData statusIcon = alert.status == 'pending'
        ? Icons.warning
        : alert.status == 'acknowledged'
            ? Icons.visibility
            : Icons.check_circle;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MapViewScreen(
                latitude: alert.latitude,
                longitude: alert.longitude,
                title: alert.type,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, color: statusColor, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.type,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      alert.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, hh:mm a').format(alert.timestamp),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  alert.status.toUpperCase(),
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                backgroundColor: statusColor,
                padding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Alert Dialog
class CustomAlertDialog extends StatefulWidget {
  final AuthService authService;
  final DatabaseService databaseService;

  CustomAlertDialog({required this.authService, required this.databaseService});

  @override
  State<CustomAlertDialog> createState() => _CustomAlertDialogState();
}

class _CustomAlertDialogState extends State<CustomAlertDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String selectedType = 'Medical Emergency';
  bool isLoading = false;

  final List<Map<String, dynamic>> alertTypes = [
    {'label': 'Medical Emergency', 'icon': Icons.local_hospital, 'color': Colors.red},
    {'label': 'Security Threat', 'icon': Icons.security, 'color': Colors.orange},
    {'label': 'Fire Emergency', 'icon': Icons.local_fire_department, 'color': Colors.deepOrange},
    {'label': 'Accident', 'icon': Icons.car_crash, 'color': Colors.purple},
    {'label': 'Suspicious Activity', 'icon': Icons.visibility, 'color': Colors.amber},
    {'label': 'Other', 'icon': Icons.help_outline, 'color': Colors.blue},
  ];

  Future<void> sendCustomAlert() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      try {
        UserModel? user = await widget.authService.getUserData(widget.authService.currentUser!.uid);
        if (user == null) throw Exception('User not found');

        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) throw Exception('Location services are disabled');

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception('Location permission denied');
          }
        }

        Position position = await Geolocator.getCurrentPosition();

        String alertId = DateTime.now().millisecondsSinceEpoch.toString();
        
        AlertModel alert = AlertModel(
          alertId: alertId,
          studentId: user.uid,
          studentName: user.name,
          type: selectedType,
          description: _descriptionController.text.trim().isEmpty 
              ? 'No additional details provided' 
              : _descriptionController.text.trim(),
          latitude: position.latitude,
          longitude: position.longitude,
          status: 'pending',
          timestamp: DateTime.now(),
        );

        await widget.databaseService.sendAlert(alert);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Alert sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Create Custom Alert',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                
                Text(
                  'Alert Type',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: alertTypes.map((type) {
                    bool isSelected = selectedType == type['label'];
                    return ChoiceChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(type['icon'], size: 18, color: isSelected ? Colors.white : type['color']),
                          SizedBox(width: 6),
                          Text(type['label']),
                        ],
                      ),
                      selectedColor: type['color'],
                      labelStyle: TextStyle(
                        // color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          selectedType = type['label'];
                        });
                      },
                    );
                  }).toList(),
                ),
                
                SizedBox(height: 20),
                
                Text(
                  'Description (Optional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Provide additional details...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    // fillColor: Colors.grey[100],
                  ),
                ),
                
                SizedBox(height: 20),
                
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your location will be included automatically',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading ? null : () => Navigator.pop(context),
                        child: Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : sendCustomAlert,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Send Alert',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}