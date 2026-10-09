import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String id;
  final String bloodType;
  final String code;
  final String phone;
  final String createdBy;
  final String? location;
  final int? units;
  final String? message;
  final String status; // active, fulfilled, expired, cancelled
  final int respondersCount;
  final List<Map<String, dynamic>> responders;
  final dynamic createdAt;

  RequestModel({
    required this.id,
    required this.bloodType,
    required this.code,
    required this.phone,
    required this.createdBy,
    this.location,
    this.units,
    this.message,
    this.status = 'active',
    this.respondersCount = 0,
    this.responders = const [],
    this.createdAt,
  });

  factory RequestModel.fromMap(Map<String, dynamic> data, String id) {
    return RequestModel(
      id: id,
      bloodType: data['bloodType'] ?? '',
      code: data['code'] ?? '',
      phone: data['phone'] ?? '',
      createdBy: data['createdBy'] ?? '',
      location: data['location'],
      units: data['units'] is int ? data['units'] : int.tryParse(data['units']?.toString() ?? ''),
      message: data['message'],
      status: data['status'] ?? 'active',
      respondersCount: data['respondersCount'] ?? 0,
      responders: List<Map<String, dynamic>>.from(
        (data['responders'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e)),
      ),
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bloodType': bloodType,
      'code': code,
      'phone': phone,
      'createdBy': createdBy,
      'location': location,
      'units': units,
      'message': message,
      'status': status,
      'respondersCount': respondersCount,
      'responders': responders,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
