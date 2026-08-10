import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  final String id;
  final String targetUid;
  final String text;
  final String postImageUrl;
  final Timestamp? timestamp;

  NotificationItem({
    this.id = '',
    this.targetUid = '',
    this.text = '',
    this.postImageUrl = '',
    this.timestamp,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map, String docId) {
    return NotificationItem(
      id: docId,
      targetUid: map['targetUid'] as String? ?? '',
      text: map['text'] as String? ?? '',
      postImageUrl: map['postImageUrl'] as String? ?? '',
      timestamp: map['timestamp'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'targetUid': targetUid,
      'text': text,
      'postImageUrl': postImageUrl,
      'timestamp': timestamp ?? Timestamp.now(),
    };
  }
}
