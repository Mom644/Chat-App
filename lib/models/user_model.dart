import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String image; // يمكن تركه فارغًا
  final String searchKey;
  final DateTime createdAt;
  

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.image,
    required this.searchKey,
    required this.createdAt,
  });

  // =========================
  // Convert Firestore → Model
  // =========================
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      image: data['image'] ?? '',
      searchKey: data['searchKey'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // =========================
  // Convert Model → Firestore
  // =========================
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'image': image,
      'searchKey': searchKey,
      'createdAt': createdAt,
    };
  }
}