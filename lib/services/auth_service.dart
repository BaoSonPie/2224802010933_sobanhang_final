import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 👉 v7: KHÔNG tạo instance kiểu cũ nữa
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<User?> signInWithGoogle() async {
    try {
      // 👉 v7: phải gọi initialize trước
      await _googleSignIn.initialize(
        serverClientId:
            "1060646689103-8d022ejcob4itte00a7lm48sfvmf6re2.apps.googleusercontent.com", // 👉 Android để null
      );

      // 👉 v7: dùng authenticate thay vì signIn
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;

      // 👉 lấy idToken
      final idToken = googleAuth.idToken;

      // 👉 tạo credential
      final credential = GoogleAuthProvider.credential(idToken: idToken);

      // 👉 đăng nhập Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      final user = userCredential.user;

      // 👉 lưu user lên Firestore
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'name': user.displayName,
        'email': user.email,
        'photo': user.photoURL,
      });

      return user;
    } catch (e) {
      dev.log("Lỗi login: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
