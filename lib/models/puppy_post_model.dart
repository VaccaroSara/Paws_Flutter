import 'package:cloud_firestore/cloud_firestore.dart';

class PuppyPost {
  final String id;
  final String uid;
  final String name;
  final String imageUrl;
  final String gender;
  final String type;
  final String age;
  final String caption;
  final String userType;
  final int likesCount;
  final Timestamp? timestamp;

  PuppyPost({
    this.id = '',
    this.uid = '',
    this.name = '',
    this.imageUrl = '',
    this.gender = 'male',
    this.type = 'Dog',
    this.age = '1 years',
    this.caption = '',
    this.userType = 'Private User',
    this.likesCount = 0,
    this.timestamp,
  });

  factory PuppyPost.fromMap(Map<String, dynamic> map, String docId) {
    return PuppyPost(
      id: docId,
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      gender: map['gender'] as String? ?? 'male',
      type: map['type'] as String? ?? 'Dog',
      age: map['age'] as String? ?? '1 years',
      caption: map['caption'] as String? ?? '',
      userType: map['userType'] as String? ?? 'Private User',
      likesCount: map['likesCount'] as int? ?? 0,
      timestamp: map['timestamp'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'imageUrl': imageUrl,
      'gender': gender,
      'type': type,
      'age': age,
      'caption': caption,
      'userType': userType,
      'timestamp': timestamp ?? Timestamp.now(),
    };
  }

  PuppyPost copyWith({
    String? id,
    String? uid,
    String? name,
    String? imageUrl,
    String? gender,
    String? type,
    String? age,
    String? caption,
    String? userType,
    int? likesCount,
    Timestamp? timestamp,
  }) {
    return PuppyPost(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      gender: gender ?? this.gender,
      type: type ?? this.type,
      age: age ?? this.age,
      caption: caption ?? this.caption,
      userType: userType ?? this.userType,
      likesCount: likesCount ?? this.likesCount,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
