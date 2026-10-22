import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../models/chat_model.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String query = "";
  final TextEditingController _searchController = TextEditingController();

  final String placeholderImage =
      "https://www.gravatar.com/avatar/placeholder?d=mp&s=200";

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // =========================
      // AppBar
      // =========================
      appBar: AppBar(
        title: Text("Chat App"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              Navigator.pushReplacementNamed(context, "/login");
            },
          )
        ],
      ),

      // =========================
      // Body
      // =========================
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search users...",
                prefixIcon: Icon(Icons.search),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      query = "";
                      _searchController.clear();
                    });
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() => query = val.trim());
              },
            ),
          ),
          SizedBox(height: 10,),

            Text("Welcome Back ${auth.user!.name}",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.blue),),

          Expanded(
            child: query.isNotEmpty
                ? _buildSearch(chatProvider, auth)
                : _buildRecentChats(chatProvider, auth),
          ),
        ],
      ),
    );
  }

  // =========================
  // 🔍 Search Users
  // =========================
  Widget _buildSearch(ChatProvider chatProvider, AuthProvider auth) {
    return StreamBuilder(
      stream: chatProvider.searchUsers(query),
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data.docs;

        if (users.isEmpty) {
          return Center(child: Text("No users found"));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, i) {
            final user = users[i];

            if (user.id == auth.userId) return SizedBox();

            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                NetworkImage(user['image'] ?? placeholderImage),
              ),
              title: Text(user['name']),
              subtitle: Text(user['email'] ?? ""),
              onTap: () async {
                final chatId = await chatProvider.createOrGetChat(
                  currentUserId: auth.userId,
                  otherUserId: user.id,
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatId: chatId,
                      receiverId: user.id,
                      receiverName: user['name'],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // =========================
  // 💬 Recent Chats
  // =========================
  Widget _buildRecentChats(ChatProvider chatProvider, AuthProvider auth) {
    return StreamBuilder<List<ChatModel>>(
      stream: chatProvider.getRecentChats(auth.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final chats = snapshot.data!;

        if (chats.isEmpty) {
          return Center(
            child: Text(
              "No chats yet 👋",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, i) {
            final chat = chats[i];

            final otherUserId =
            chat.participants.firstWhere((id) => id != auth.userId);

            return FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUserId)
                  .get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return SizedBox();

                final user = userSnap.data!;

                return Container(
                  margin:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10),

                    // Avatar
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundImage:
                      NetworkImage(user['image'] ?? placeholderImage),
                    ),

                    // Name + Message
                    title: Text(
                      user['name'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      chat.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Time
                    trailing: Text(
                      _formatTime(chat.updatedAt),
                      style: TextStyle(fontSize: 12),
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: chat.chatId,
                            receiverId: otherUserId,
                            receiverName: user['name'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // =========================
  // ⏰ Format Time
  // =========================
  String _formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}