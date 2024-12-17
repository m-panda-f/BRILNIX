import 'package:brilnix/community/Search_group.dart';
import 'package:brilnix/courses/course.dart';
import 'package:brilnix/home.dart';
import 'package:brilnix/widgets/header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  ChatScreenState createState() => ChatScreenState();
}
class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  final String apiKey = 'AIzaSyCf9QA-FCMhL-_2a_em0F2wPmBTbgYg4eY'; // Replace with your actual API key
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get todayDate => DateFormat('yyyy-MM-dd').format(DateTime.now());
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userName;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadConversation();
  }

  // Fetch current user data (name, etc.)
  Future<void> _fetchUserData() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      setState(() {
        userName = userSnapshot['name'] ?? "No Name";
      });
    }
  }

  // Save conversation to Firestore with a specific user document
  Future<void> _saveConversation() async {
    final messagesData = _messages.map((msg) {
      return {
        'text': msg.text,
        'sender': msg.sender,
      };
    }).toList();

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection('chatbot_conversations').doc(currentUser.uid).set({
        'messages': messagesData,
        'name': userName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  // Load conversation from Firestore for the specific user
  Future<void> _loadConversation() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final snapshot = await _firestore
          .collection('chatbot_conversations')
          .doc(currentUser.uid)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data()!;
        final timestamp = data['timestamp'] as Timestamp;

        // Check if the conversation is older than 7 days
        if (DateTime.now().difference(timestamp.toDate()).inDays > 7) {
          await _deleteConversation();
        } else {
          setState(() {
            _messages.addAll((data['messages'] as List<dynamic>).map((msg) {
              return ChatMessage(
                text: msg['text'],
                sender: msg['sender'],
              );
            }).toList());
          });
        }
      }
    }
  }

  // Delete conversation after 7 days
  Future<void> _deleteConversation() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection('conversations').doc(currentUser.uid).delete();
      setState(() {
        _messages.clear();
      });
    }
  }

  // Send a message and get a response from AI
   Future<void> _sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, sender: 'user'));
      _isTyping = true;
    });

    _controller.clear();
    await _saveConversation();

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );

    try {
      final response = await model.generateContent([Content.text(text)]);

      setState(() {
        _messages.add(ChatMessage(
          text: response.text ?? 'Sorry, I could not understand that.',
          sender: 'bot',
        ));
      });
      await _saveConversation();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Error: Could not generate a response.',
          sender: 'bot',
        ));
      });
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable back button
      child: Scaffold(
        appBar:CustomAppBar(
          title:  'Brilit',
          showUploadButton: false,
        ),
        body: Column(
          children: [
            // Display previous conversations
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Align(
                    alignment: message.sender == 'user'
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 5.0, horizontal: 10.0),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 15.0),
                      decoration: BoxDecoration(
                        color: message.sender == 'user'
                            ? Colors.blueAccent
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: message.sender == 'user'
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: const [
                    Icon(Icons.timelapse, color: Colors.grey),
                    SizedBox(width: 10),
                    Text(
                      "AI is typing...",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: () {
                      _sendMessage(_controller.text);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          color: const Color(0xFF7A1FCA),
          shape: const CircularNotchedRectangle(),
          notchMargin: 5.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.groups_3_outlined, size: 30),
                color: Colors.white,
                
                onPressed: () {
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>  GroupListScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.chat, size: 30),
                color: Colors.white,
                onPressed: () {
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.home_outlined, size: 30),
                color: Colors.white,
                onPressed: () {
                
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VideoFeedPage()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.article_outlined, size: 30),
                color: Colors.white,
                onPressed: () {
               
                },
              ),
              IconButton(
                icon: const Icon(Icons.menu_book_sharp, size: 30),
                color: Colors.white,
                onPressed: () {
                 
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CourseListPage()),
                  );
                }
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final String sender;

  ChatMessage({required this.text, required this.sender});
}
