class AlertModel{
    final String alertId;
    final String studentId;
    final String studentName;
    final String type;
    final String description;
    final double latitude;
    final double longitude;
    final String status;
    final DateTime timestamp;

    AlertModel({
        required this.alertId,
        required this.studentId,
        required this.studentName,
        required this.type,
        required this.description,
        required this.latitude,
        required this.longitude,
        required this.status,
        required this.timestamp,
    });

    Map<String, dynamic> toMap(){
        return{
            'alertId': alertId,
            'studentId': studentId,
            'studentName': studentName,
            'type': type,
            'description': description,
            'latitude': latitude,
            'longitude': longitude,
            'status': status,
            'timestamp': timestamp.toIso8601String(),
        };
    }

    factory AlertModel.fromMap(Map<String, dynamic> map){
        return AlertModel(
            alertId: map['alertId'] ?? '',
            studentId: map['studentId'] ?? '',
            studentName: map['studentName'] ?? '',
            type: map['type'] ?? 'other',
            description: map['description'] ?? '',
            latitude: (map['latitude'] ?? 0).toDouble(),
            longitude: (map['longitude'] ?? 0).toDouble(),
            status: map['status'] ?? 'pending',
            timestamp: DateTime.parse(map['timestamp']),
        );
    }
}
