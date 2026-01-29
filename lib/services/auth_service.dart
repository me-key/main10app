import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/user_profile.dart';

class AuthService {
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  AuthService() 
      : _auth = _tryGetAuth(),
        _firestore = _tryGetFirestore();

  static FirebaseAuth? _tryGetAuth() {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      print("AuthService: Firebase Auth not available.");
      return null;
    }
  }

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      print("AuthService: Firestore not available.");
      return null;
    }
  }

  Stream<User?> get authStateChanges {
    if (_auth == null) return Stream.value(null);
    return _auth!.authStateChanges();
  }
  
  User? get currentUser => _auth?.currentUser;
  
  String? get currentUserId => _auth?.currentUser?.uid;

  Future<UserProfile?> getUserProfile(String uid) async {
    if (_firestore == null) return null;
    
    print("AuthService: Fetching user profile for $uid...");
    final stopwatch = Stopwatch()..start();

    DocumentSnapshot? doc;

    try {
      // Try fetching from server first with a short timeout (3s)
      // This prevents the 30s "hanging" if the connection is flaky/blocked
      doc = await _firestore!
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 3));
      
      print("AuthService: Fetched profile from server in ${stopwatch.elapsedMilliseconds}ms");
    } catch (e) {
      print("AuthService: Server fetch failed/timed out (${stopwatch.elapsedMilliseconds}ms). Error: $e");
      print("AuthService: Falling back to cache...");
      
      try {
        doc = await _firestore!
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
        print("AuthService: Fetched profile from cache in ${stopwatch.elapsedMilliseconds}ms");
      } catch (e2) {
        print("AuthService: Cache fetch failed: $e2");
      }
    }

    if (doc != null && doc.exists) {
      return UserProfile.fromMap(uid, doc.data() as Map<String, dynamic>);
    }
    
    return null;
  }

  Future<User?> signIn(String email, String password) async {
    if (_auth == null) {
      print("AuthService: Firebase Auth not initialized.");
      return null;
    }
    
    final stopwatch = Stopwatch()..start();
    print("AuthService: Attempting sign in for $email...");

    try {
      UserCredential result = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("AuthService: Sign in successful in ${stopwatch.elapsedMilliseconds}ms");
      return result.user;
    } catch (e) {
      print("AuthService: Sign in failed after ${stopwatch.elapsedMilliseconds}ms. Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    if (_auth != null) await _auth!.signOut();
  }
  
  Future<void> createUser(String email, String password, String role, String name, String phoneNumber) async {
      if (_auth == null || _firestore == null) return;
      try {
        UserCredential result = await _auth!.createUserWithEmailAndPassword(email: email, password: password);
        User? user = result.user;
        if (user != null) {
          await _firestore!.collection('users').doc(user.uid).set({
            'email': email,
            'displayName': name,
            'role': role,
            'phoneNumber': phoneNumber,
          });
        }
      } catch (e) {
        print(e);
      }
  }
}
