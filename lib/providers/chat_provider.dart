import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_model.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;
  String? error;

  // =========================
  // Create or Get Chat
  // =========================
  Future<String> createOrGetChat({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      final query = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      for (var doc in query.docs) {
        List participants = doc['participants'];

        if (participants.contains(otherUserId)) {
          return doc.id;
        }
      }

      final chatRef = _firestore.collection('chats').doc();

      await chatRef.set({
        'participants': [currentUserId, otherUserId],
        'lastMessage': "",
        'lastSenderId': "",
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return chatRef.id;
    } catch (e) {
      error = "Failed to create chat";
      notifyListeners();
      rethrow;
    }
  }

  // =========================
  // Send Message
  // =========================
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);

      // 1️⃣ Add message
      await chatRef.collection('messages').add({
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2️⃣ Update chat (🔥 مهم جدًا)
      await chatRef.set({
        'participants': [senderId, receiverId],
        'lastMessage': text,
        'lastSenderId': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      error = "Failed to send message";
      notifyListeners();
    }
  }

  // =========================
  // Get Messages
  // =========================
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // =========================
  // Get Recent Chats (🔥 FIXED)
  // =========================
  Stream<List<ChatModel>> getRecentChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final chats = snapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
          .toList();

      // 🔥 ترتيب يدوي (حل مشكلة index)
      chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return chats;
    });
  }

  // =========================
  // Search Users
  // =========================
  Stream<QuerySnapshot> searchUsers(String query) {
    return _firestore
        .collection('users')
        .where('searchKey', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('searchKey', isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff')
        .snapshots();
  }

  // =========================
  // Delete Message (Optional)
  // =========================
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      error = "Failed to delete message";
      notifyListeners();
    }
  }

  // =========================
  // Clear Chat (Optional)
  // =========================
  Future<void> clearChat(String chatId) async {
    try {
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      for (var doc in messages.docs) {
        await doc.reference.delete();
      }

      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': "",
      });
    } catch (e) {
      error = "Failed to clear chat";
      notifyListeners();
    }
  }
}