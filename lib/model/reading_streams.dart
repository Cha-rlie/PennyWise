import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReadingStreams {
  // Singleton instance
  static ReadingStreams? _instance;

  late final String userId;
  final _firestore = FirebaseFirestore.instance;
  // Flag to stop going straight to MainApp Page right after authentication
  // This is a problem because it skips loading the data correctly into Firestore
  static final ValueNotifier<bool> isPostAuthDataComplete = ValueNotifier(false);

  // Singleton pattern implementation where this constructor is private to this file only
  ReadingStreams._(String userId) {this.userId = userId;}

  static void initialize(String userId) {
    _instance = ReadingStreams._(userId);
  }

  static ReadingStreams? getInstanceOrNull() {
    return _instance;
  }

  static ReadingStreams getInstance() {
    return _instance!;
  }

  // To be called when user logs out to prevent memory leaks and unintended data access across users
  static void dispose() {
    _instance = null;
  }

  // All the streams that the app will listen to for real-time updates from Firebase Firestore
  late final Stream<DocumentSnapshot> publicUserStream = _firestore.collection("public-users").doc(userId).snapshots().asBroadcastStream();
  late final Stream<DocumentSnapshot> privateUserStream = _firestore.collection("private-users").doc(userId).snapshots().asBroadcastStream();
  late final Stream<QuerySnapshot> debtsOwedStream = _firestore.collection("debts").where("owedTo", isEqualTo: userId).snapshots().asBroadcastStream();
  late final Stream<QuerySnapshot> debtsOwingStream = _firestore.collection("debts").where("owedBy", isEqualTo: userId).snapshots().asBroadcastStream();
  late final Stream<QuerySnapshot> expensesStream = _firestore.collection("expenses").where("participants", arrayContains: userId).snapshots().asBroadcastStream();
  late final Stream<QuerySnapshot> friendshipsStream = _firestore.collection("friendships").where("members", arrayContains: userId).snapshots().asBroadcastStream();
  late final Stream<QuerySnapshot> tripsStream = _firestore.collection("trips").where("members", arrayContains: userId).snapshots().asBroadcastStream();

}