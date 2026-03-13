import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

// lib/services/auth_service.dart
class AuthService extends GetxService {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  final user    = Rxn<User>();
  final profile = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state
    _auth.authStateChanges().listen((u) async {
      user.value = u;
      if (u != null) await _loadProfile(u.uid);
    });
  }

  // Google Sign-In
  Future<bool> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return false;
    final cred = GoogleAuthProvider.credential(
      accessToken: (await googleUser.authentication).accessToken,
      idToken:     (await googleUser.authentication).idToken,
    );
    await _auth.signInWithCredential(cred);
    return true;
  }

  // Save onboarding profile to Firestore
  Future<void> saveProfile(Map<String, dynamic> data) async {
    final uid = _auth.currentUser!.uid;
    await _db.doc('users/$uid/profile').set(data, SetOptions(merge: true));
    profile.value = data;
  }

  Future<void> _loadProfile(String uid) async {
    final doc = await _db.doc('users/$uid/profile').get();
    if (doc.exists) profile.value = doc.data();
  }

  Future<void> signOut() => _auth.signOut();
  bool get isLoggedIn => _auth.currentUser != null;
}