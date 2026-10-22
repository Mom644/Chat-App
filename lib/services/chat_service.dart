import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  // search users
  Stream<QuerySnapshot> searchUsers(String query) {
    return _db
        .collection('users')
        .where('searchKey', isGreaterThanOrEqualTo: query.toLowerCase())
        .snapshots();
  }

  // generate chatId
  String getChatId(String a, String b) {
    return a.hashCode <= b.hashCode ? '$a-$b' : '$b-$a';
  }

  // send message
  Future<void> sendMessage(
      String senderId, String receiverId, String text) async {
    final chatId = getChatId(senderId, receiverId);

    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.now(),
    });
  }

  // get messages
  Stream<QuerySnapshot> getMessages(String user1, String user2) {
    final chatId = getChatId(user1, user2);

    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }
}