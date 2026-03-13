// lib/features/auth/controllers/auth_controller.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';                   // ← ADD THIS IMPORT
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/firestore_repository.dart';

class AuthController extends GetxController {
  final _auth      = FirebaseAuth.instance;
  final _googleSI  = GoogleSignIn();
  final _repo      = FirestoreRepository();

  final user       = Rxn<UserModel>();
  final isLoading  = false.obs;
  final error      = RxnString();

  @override
  void onInit() {
    super.onInit();
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      user.value = null;
      // ✅ Wait for first frame before navigating — fixes stuck on splash
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(AppK.routeAuth);
      });
      return;
    }

    final profile = await _repo.getUser(firebaseUser.uid);
    user.value = profile ?? await _createProfile(firebaseUser);

    // ✅ Same fix for successful auth navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed(AppK.routeHome);
    });
  }

  Future<UserModel> _createProfile(User fu) async {
    final model = UserModel(
      uid:       fu.uid,
      name:      fu.displayName ?? 'Learner',
      email:     fu.email       ?? '',
      photoUrl:  fu.photoURL,
      createdAt: DateTime.now(),
    );
    await _repo.createUser(model);
    return model;
  }

  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    error.value     = null;
    try {
      final gUser = await _googleSI.signIn();
      if (gUser == null) { isLoading.value = false; return; }
      final cred   = await gUser.authentication;
      final fbCred = GoogleAuthProvider.credential(
        idToken:     cred.idToken,
        accessToken: cred.accessToken,
      );
      await _auth.signInWithCredential(fbCred);
      // Navigation handled by _onAuthStateChanged listener above
    } catch (e) {
      error.value = 'Sign-in failed: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    await _googleSI.signOut();
    await _auth.signOut();
  }

  Future<void> updateProfile(Map<String, dynamic> fields) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _repo.updateUser(uid, fields);
    final updated = await _repo.getUser(uid);
    user.value = updated;
  }

  String get uid => _auth.currentUser?.uid ?? '';
}