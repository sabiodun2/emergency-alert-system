import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert_model.dart';

class DatabaseService{
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    Future<void> sendAlert(AlertModel alert) async{
        await firestore.collection('alerts').doc(alert.alertId).set(alert.toMap());
    }
}