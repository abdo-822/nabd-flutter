import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';
import '../models/user_model.dart';

class DataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// إنشاء طلب دم جديد
  Future<String> createBloodRequest(Map<String, dynamic> requestData) async {
    final docRef = await _firestore.collection('requests').add({
      ...requestData,
      'status': 'active',
      'respondersCount': 0,
      'responders': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// الاستماع للطلبات النشطة لحظياً
  Stream<List<RequestModel>> listenToActiveRequests({String? bloodType, String? city}) {
    Query query = _firestore.collection('requests')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(100);

    if (bloodType != null && bloodType.isNotEmpty) {
      query = query.where('bloodType', isEqualTo: bloodType);
    }
    if (city != null && city.isNotEmpty) {
      query = query.where('location', isEqualTo: city);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return RequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// الاستماع لطلبات المستخدم الخاصة لحظياً
  Stream<List<RequestModel>> listenToUserRequests(String userId) {
    return _firestore
        .collection('requests')
        .where('createdBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return RequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      // ترتيب حسب التاريخ
      list.sort((a, b) => (b.createdAt?.toString() ?? '').compareTo(a.createdAt?.toString() ?? ''));
      return list;
    });
  }

  /// قبول طلب تبرع مع تطبيق فترة الراحة 8 أسابيع
  Future<bool> acceptBloodRequestWithCooldown({
    required String requestId,
    required String donorId,
    required Map<String, dynamic> donorInfo,
  }) async {
    final userRef = _firestore.collection('users').doc(donorId);
    final userSnap = await userRef.get();
    final userData = userSnap.data();

    // فحص فترة الراحة (56 يوماً)
    final dynamic lastDonation = userData?['lastDonationDate'];
    if (lastDonation != null) {
      final int lastDonationMs = lastDonation is int ? lastDonation : int.tryParse(lastDonation.toString()) ?? 0;
      if (lastDonationMs > 0) {
        final int cooldownEnd = lastDonationMs + (56 * 24 * 60 * 60 * 1000);
        final int now = DateTime.now().millisecondsSinceEpoch;
        if (now < cooldownEnd) {
          final int daysLeft = ((cooldownEnd - now) / (24 * 60 * 60 * 1000)).ceil();
          throw Exception('لا يمكنك التبرع الآن. فترة الراحة 8 أسابيع. متبقي $daysLeft يوم.');
        }
      }
    }

    // تسجيل تاريخ التبرع وتحديث عدد التبرعات
    await userRef.update({
      'lastDonationDate': DateTime.now().millisecondsSinceEpoch,
      'donations': FieldValue.increment(1),
    });

    // إضافة المستجيب للطلب
    final requestRef = _firestore.collection('requests').doc(requestId);
    await requestRef.update({
      'respondersCount': FieldValue.increment(1),
      'responders': FieldValue.arrayUnion([
        {
          'userId': donorId,
          'bloodType': donorInfo['bloodType'] ?? '',
          'phone': donorInfo['phone'] ?? '',
          'city': donorInfo['city'] ?? '',
          'timestamp': DateTime.now().toIso8601String(),
        }
      ]),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    return true;
  }

  /// تحديث بيانات طلب دم
  Future<void> updateBloodRequest(String requestId, Map<String, dynamic> data) async {
    await _firestore.collection('requests').doc(requestId).update({
      ...data,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// حذف طلب دم
  Future<void> deleteBloodRequest(String requestId) async {
    await _firestore.collection('requests').doc(requestId).delete();
  }

  /// جلب طلب واحد بواسطة المعرف
  Future<RequestModel?> getRequest(String requestId) async {
    final doc = await _firestore.collection('requests').doc(requestId).get();
    if (!doc.exists) return null;
    return RequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// الاستماع لطلب واحد لحظياً
  Stream<RequestModel?> listenToRequest(String requestId) {
    return _firestore.collection('requests').doc(requestId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return RequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  /// جلب قائمة المتبرعين المسجلين
  Future<List<UserModel>> getDonors() async {
    final snap = await _firestore.collection('users').get();
    return snap.docs
        .map((d) => UserModel.fromMap(d.data(), d.id))
        .where((u) => u.bloodType.isNotEmpty)
        .toList();
  }

  /// تحديث بيانات المستخدم
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  /// تبديل حالة توفر المتبرع
  Future<void> setDonorActive(String uid, bool isActive) async {
    await _firestore.collection('users').doc(uid).update({'isActive': isActive});
  }
}

