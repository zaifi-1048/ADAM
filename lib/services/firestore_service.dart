import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_voice_chat/models/user_model.dart';

/// Handles user-profile CRUD in Firestore.
///
/// For chat and tasks, use [ChatService] and [TaskService] respectively.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  // ─── Create ───────────────────────────────────────────────────────────────

  Future<void> createUser(UserModel user) async {
    await _userDoc(user.uid).set(user.toMap());
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  Future<UserModel?> getUser(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }

  /// Real-time stream of the current user's profile.
  Stream<UserModel?> watchUser(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _userDoc(uid).update(data);
  }

  /// Stamps the user's lastSeen to now.
  Future<void> touchLastSeen(String uid) async {
    await _userDoc(uid).update({
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // ─── Upsert (for Google Sign-In — user may already exist) ────────────────

  Future<void> upsertUser(UserModel user) async {
    final doc = await _userDoc(user.uid).get();
    if (doc.exists) {
      await updateUser(user.uid, {
        'lastSeen': FieldValue.serverTimestamp(),
        'photoUrl': user.photoUrl,
      });
    } else {
      await createUser(user);
    }
  }
}
