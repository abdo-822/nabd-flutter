class UserModel {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String bloodType;
  final String location;
  final bool isActive;
  final int? lastDonationDate;
  final int donations;
  final List<String> pushTokens;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    required this.bloodType,
    required this.location,
    this.isActive = true,
    this.lastDonationDate,
    this.donations = 0,
    this.pushTokens = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      bloodType: data['bloodType'] ?? '',
      location: data['location'] ?? '',
      isActive: data['isActive'] != false,
      lastDonationDate: data['lastDonationDate'] is int
          ? data['lastDonationDate']
          : int.tryParse(data['lastDonationDate']?.toString() ?? ''),
      donations: data['donations'] ?? 0,
      pushTokens: List<String>.from(data['pushTokens'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'bloodType': bloodType,
      'location': location,
      'isActive': isActive,
      'lastDonationDate': lastDonationDate,
      'donations': donations,
      'pushTokens': pushTokens,
    };
  }
}
