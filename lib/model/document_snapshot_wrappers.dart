// DocumentSnapshot types cannot be distinguished
// These wrapper classes provide a way to distinguish them

import 'package:cloud_firestore/cloud_firestore.dart';

class PublicUser {
  final Map<String, dynamic> data;
  PublicUser(this.data);
  String get email => data["email"];
  String get username => data["username"];
  bool get requireFriendApproval => data["requireFriendApproval"];
}

class PrivateUser {
  final Map<String, dynamic> data;
  PrivateUser(this.data);
  double get totalDebt => data["totalDebt"];
  String get preferredCurrency => data["preferredCurrency"];
  bool get automaticallyLogOut => data["automaticallyLogOut"];
  bool get notifications => data["notifications"];
  String get paymentReminderFrequency => data["paymentReminderFrequency"];
}

class Friendships {
  final List<Map<String, dynamic>> friends;
  Friendships(this.friends);
}

class Trips {
  final List<QueryDocumentSnapshot> documents;
  Trips(this.documents);
}