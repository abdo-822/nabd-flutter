import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUserModel;
  UserModel? get currentUserModel => _currentUserModel;
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  AuthService() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await reloadUserData();
      } else {
        _currentUserModel = null;
        notifyListeners();
      }
    });
  }

  /// إعادة تحميل بيانات المستخدم الحالية
  Future<void> reloadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      _currentUserModel = await getUserData(user.uid);
      notifyListeners();
    }
  }

  /// تسجيل الدخول بالبريد وكلمة المرور
  Future<UserCredential> loginWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    if (cred.user != null) {
      _currentUserModel = await getUserData(cred.user!.uid);
      notifyListeners();
    }
    return cred;
  }

  /// إنشاء حساب جديد وحفظ البيانات في Firestore
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String bloodType,
    required String location,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = cred.user;
    if (user != null) {
      final userModel = UserModel(
        uid: user.uid,
        email: email.trim(),
        name: name.trim(),
        phone: phone.trim(),
        bloodType: bloodType,
        location: location,
        isActive: true,
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
      _currentUserModel = userModel;
      notifyListeners();
    }
    return cred;
  }

  /// إعادة تعيين كلمة المرور
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// جلب بيانات المستخدم من Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// تحديث بيانات المستخدم
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
    await reloadUserData();
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    await _auth.signOut();
    _currentUserModel = null;
    notifyListeners();
  }

  Future<void> signOut() => logout();

  /// ترجمة أخطاء Firebase للغة العربية
  static String getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'invalid-credential':
        return 'بيانات الدخول غير صحيحة، يرجى التأكد من البريد وكلمة المرور';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صالحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مسجل بالفعل لمستخدم آخر';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً (يجب ألا تقل عن 6 خانات)';
      case 'too-many-requests':
        return 'تم حظر الحساب مؤقتاً لكثرة المحاولات، يرجى المحاولة لاحقاً';
      case 'network-request-failed':
        return 'تعذر الاتصال بالشبكة، تأكد من اتصال الإنترنت';
      default:
        return 'حدث خطأ، يرجى المحاولة مرة أخرى';
    }
  }
}
