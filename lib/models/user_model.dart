import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String fullName;
  final String region;
  final String country;
  final String phone;
  final DateTime? createdAt;
  final bool isActive;
  final DateTime? subscriptionExpiry;
  final String? activePackageId;

  UserModel({
    required this.id,
    required this.fullName,
    required this.region,
    required this.country,
    required this.phone,
    this.createdAt,
    this.isActive = false,
    this.subscriptionExpiry,
    this.activePackageId,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      fullName: data['fullName'] ?? 'Unknown',
      region: data['region'] ?? 'Unknown',
      country: data['country'] ?? 'Unknown',
      phone: data['phone'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] == true,
      subscriptionExpiry: data['subscriptionExpiry'] != null
          ? (data['subscriptionExpiry'] as Timestamp).toDate()
          : null,
      activePackageId: data['activePackageId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'region': region,
      'country': country,
      'phone': phone,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
