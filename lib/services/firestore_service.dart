import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class FirestoreService {
  final CollectionReference profilesCollection =
  FirebaseFirestore.instance.collection("profiles");

  Future<void> saveUserProfile(String userId, UserProfile profile) async {
    await profilesCollection.doc(userId).set(profile.toMap());
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final doc = await profilesCollection.doc(userId).get();
    if (doc.exists) {
      return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }
}
