import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.receiverId,
    required this.receiverName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // =====================
  // Send Message
  // =====================
  void sendMessage(ChatProvider chatProvider, String senderId) async {
    final text = _controller.text.trim();

    if (text.isEmpty) return;

    await chatProvider.sendMessage(
      chatId: widget.chatId,
      senderId: senderId,
      receiverId: widget.receiverId,
      text: text,
    );

    _controller.clear();

    // Auto Scroll
    Future.delayed(Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade200,

      // =====================
      // AppBar
      // =====================
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              child: Icon(Icons.person),
            ),
            SizedBox(width: 10),
            Text(widget.receiverName),
          ],
        ),
      ),

      // =====================
      // Body
      // =====================
      body: Column(
        children: [
          // =====================
          // Messages List
          // =====================
          Expanded(
            child: StreamBuilder(
              stream: chatProvider.getMessages(widget.chatId),
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    snapshot.data.docs.isEmpty) {
                  return _buildEmptyChat();
                }

                final messages = snapshot.data.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];

                    final isMe =
                        msg['senderId'] == auth.userId;

                    return _buildMessageBubble(
                      text: msg['text'],
                      isMe: isMe,
                      timestamp: msg['timestamp'],
                    );
                  },
                );
              },
            ),
          ),

          // =====================
          // Input Field
          // =====================
          _buildInput(chatProvider, auth.userId),
        ],
      ),
    );
  }

  // =====================
  // Message Bubble
  // =====================
  Widget _buildMessageBubble({
    required String text,
    required bool isMe,
    required dynamic timestamp,
  }) {
    return Align(
      alignment:
      isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _formatTime(timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================
  // Input UI
  // =====================
  Widget _buildInput(ChatProvider chatProvider, String senderId) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: IconButton(
                icon: Icon(Icons.send, color: Colors.white),
                onPressed: () =>
                    sendMessage(chatProvider, senderId),
              ),
            )
          ],
        ),
      ),
    );
  }

  // =====================
  // Empty Chat
  // =====================
  Widget _buildEmptyChat() {
    return Center(
      child: Text(
        "Start conversation 👋",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  // =====================
  // Format Time
  // =====================
  String _formatTime(dynamic timestamp) {
    try {
      final time = timestamp.toDate();
      return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "";
    }
  }
}