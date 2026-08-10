import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/puppy_post_model.dart';
import '../models/notification_model.dart';
import 'supabase_service.dart';

class FirebaseService {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  static User? get currentUser => auth.currentUser;

  // --- AUTHENTICATION ---

  static Future<UserCredential> signIn(String email, String password) async {
    return await auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  static Future<void> signUp({
    required String firstName,
    required String lastName,
    required String city,
    required String province,
    required String cap,
    required String username,
    required String email,
    required String password,
    required String phone,
    required String accountType,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // Create Firebase Auth user
    final cred = await auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final uid = cred.user?.uid;
    if (uid == null) throw Exception("Failed to get UID after signup.");

    try {
      // Check if username is already taken
      final querySnapshot = await db
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Username taken -> delete auth user & throw exception
        await cred.user?.delete();
        throw Exception("Username già in uso. Scegline un altro.");
      }

      // Save user profile in Firestore
      final userData = {
        'firstName': firstName,
        'lastName': lastName,
        'city': city,
        'province': province,
        'cap': cap,
        'username': username,
        'email': cleanEmail,
        'phone': phone,
        'accountType': accountType,
      };

      await db.collection('users').doc(uid).set(userData);
    } catch (e) {
      await cred.user?.delete();
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await auth.signOut();
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    await auth.sendPasswordResetEmail(email: email);
  }

  static Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;
    final uid = user.uid;

    // 1. Get user posts
    final postsSnap = await db.collection('posts').where('uid', isEqualTo: uid).get();
    final postIds = postsSnap.docs.map((d) => d.id).toList();

    // 2. Batch delete user posts and user doc
    final batch = db.batch();
    for (var doc in postsSnap.docs) {
      batch.delete(doc.reference);
    }

    // Delete user's document
    batch.delete(db.collection('users').doc(uid));
    await batch.commit();

    // 3. Delete files from Supabase Storage
    await SupabaseService.deleteAllUserDataFromSupabase(uid, postIds);

    // 4. Delete Auth user
    await user.delete();
  }

  // --- FIRESTORE STREAMS & DATA ---

  static Stream<UserModel?> userStream(String uid) {
    return db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserModel.fromMap(snapshot.data()!, snapshot.id);
    });
  }

  static Future<UserModel?> getUser(String uid) async {
    final doc = await db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  static Future<void> updateUserFields(String uid, Map<String, dynamic> updates) async {
    await db.collection('users').doc(uid).update(updates);
  }

  static Stream<List<PuppyPost>> globalFeedStream(String currentUid) {
    return db
        .collection('posts')
        .where('uid', isNotEqualTo: currentUid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PuppyPost.fromMap(doc.data(), doc.id))
            .toList());
  }

  static Stream<List<PuppyPost>> myPostsStream(String uid) {
    return db
        .collection('posts')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PuppyPost.fromMap(doc.data(), doc.id))
            .toList());
  }

  static Stream<List<PuppyPost>> userPostsStream(String uid) {
    return db
        .collection('posts')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PuppyPost.fromMap(doc.data(), doc.id))
            .toList());
  }

  static Stream<Set<String>> favoritesIdsStream(String currentUid) {
    return db
        .collection('favorites')
        .where('uid', isEqualTo: currentUid)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((d) => d.getString('postId') ?? '').where((id) => id.isNotEmpty).toSet());
  }

  static Stream<int> postFavoritesCountStream(String postId) {
    return db
        .collection('favorites')
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  static Stream<bool> isPostFavoritedStream(String currentUid, String postId) {
    final favId = "${currentUid}_$postId";
    return db
        .collection('favorites')
        .doc(favId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  static Stream<List<NotificationItem>> notificationsStream(String targetUid) {
    return db
        .collection('notifications')
        .where('targetUid', isEqualTo: targetUid)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => NotificationItem.fromMap(doc.data(), doc.id))
          .toList();
      items.sort((a, b) {
        if (a.timestamp == null || b.timestamp == null) return 0;
        return b.timestamp!.compareTo(a.timestamp!);
      });
      return items;
    });
  }

  static Future<void> favoritePost(PuppyPost post) async {
    final user = currentUser;
    if (user == null) return;
    final favId = "${user.uid}_${post.id}";

    final favDoc = await db.collection('favorites').doc(favId).get();
    if (favDoc.exists) return; // Already favorited

    final userDoc = await db.collection('users').doc(user.uid).get();
    final currentUsername = userDoc.data()?['username'] as String? ?? 'someone';

    final favoriteData = {
      'uid': user.uid,
      'postId': post.id,
      'name': post.name,
      'imageUrl': post.imageUrl,
      'gender': post.gender,
      'type': post.type,
      'age': post.age,
      'caption': post.caption,
      'userType': post.userType,
      'timestamp': Timestamp.now(),
    };

    await db.collection('favorites').doc(favId).set(favoriteData);

    // Send notification to post owner
    if (post.uid != user.uid) {
      final notifData = {
        'targetUid': post.uid,
        'text': '$currentUsername added ${post.name} to favorites',
        'postImageUrl': post.imageUrl,
        'timestamp': Timestamp.now(),
      };
      await db.collection('notifications').add(notifData);
    }
  }

  static Future<void> unlikePost(String postId) async {
    final user = currentUser;
    if (user == null) return;
    final favId = "${user.uid}_$postId";
    await db.collection('favorites').doc(favId).delete();
  }

  static Future<void> toggleFavoritePost(PuppyPost post) async {
    final user = currentUser;
    if (user == null) return;
    final favId = "${user.uid}_${post.id}";
    final favDoc = await db.collection('favorites').doc(favId).get();

    if (favDoc.exists) {
      await db.collection('favorites').doc(favId).delete();
    } else {
      await favoritePost(post);
    }
  }

  static Future<void> savePost(Map<String, dynamic> postData, String postId) async {
    await db.collection('posts').doc(postId).set(postData);
  }

  static Future<void> updatePost(String postId, Map<String, dynamic> updateData) async {
    await db.collection('posts').doc(postId).update(updateData);
  }

  static Future<void> deletePost(PuppyPost post) async {
    // 1. Notify users who favorited this post
    final favsSnap = await db.collection('favorites').where('postId', isEqualTo: post.id).get();
    final batch = db.batch();

    for (var doc in favsSnap.docs) {
      final favoritedUid = doc.data()['uid'] as String?;
      if (favoritedUid != null && favoritedUid != post.uid) {
        final notifRef = db.collection('notifications').doc();
        batch.set(notifRef, {
          'id': notifRef.id,
          'targetUid': favoritedUid,
          'text': '${post.name} non è più disponibile (eliminato dal proprietario)',
          'timestamp': Timestamp.now(),
        });
      }
      batch.delete(doc.reference);
    }

    await batch.commit();

    // 2. Delete post image from Supabase
    await SupabaseService.deletePostImage(post.id);

    // 3. Delete post document from Firestore
    await db.collection('posts').doc(post.id).delete();
  }

  static Future<void> clearAllNotifications(String targetUid) async {
    final snapshots = await db
        .collection('notifications')
        .where('targetUid', isEqualTo: targetUid)
        .get();

    final batch = db.batch();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  static Future<List<UserModel>> searchUsers(String query, String currentUid) async {
    if (query.isEmpty || query.length < 2) return [];

    final snapshots = await db
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return snapshots.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .where((user) => user.uid != currentUid)
        .toList();
  }
}

extension FirestoreDocumentExt on DocumentSnapshot {
  String? getString(String field) {
    if (!exists || data() == null) return null;
    final map = data() as Map<String, dynamic>;
    return map[field] as String?;
  }
}
