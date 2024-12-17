import 'package:brilnix/community/groupchat.dart';
import 'package:brilnix/courses/course.dart';
import 'package:brilnix/home.dart';
import 'package:brilnix/templates/chatbot.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:brilnix/community/Create_group.dart';
import 'package:brilnix/community/view_group.dart';

class GroupListScreen extends StatefulWidget {
  @override
  _GroupListScreenState createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final String groupId = ''; // Initialize with a default value
  String? currentUserId; // Fetch dynamically from FirebaseAuth
  late Stream<QuerySnapshot> _groupStream;

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser();
  }

  // Initialize current user and set up the group stream
  Future<void> _initializeCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
        _groupStream = _getGroupsStream();
      });
    } else {
      // Handle unauthenticated state
      setState(() {
        currentUserId = null;
      });
    }
  }

  // Stream to get groups based on user membership
  Stream<QuerySnapshot> _getGroupsStream() {
    if (currentUserId == null) {
      // Empty stream for unauthenticated users
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('groups')
        .orderBy('name')
        .snapshots();
  }

  void _updateStream() {
    setState(() {
      _groupStream = _getGroupsStream();
    });
  }
  
  Future<void> joinGroup(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in. Please log in to join.')),
      );
      return;
    }

    try {
      final groupDoc = FirebaseFirestore.instance.collection('groups').doc(groupId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(groupDoc);
        final members = List<String>.from(snapshot['members']);

        if (!members.contains(user.uid)) {
          members.add(user.uid);
          transaction.update(groupDoc, {'members': members});
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have joined the group!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join group: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateGroupScreen()),
              );
            },
          ),
        ],
      ),
      body: currentUserId == null
          ? const Center(
              child: Text('Please log in to view your groups.'),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search Groups',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                        _updateStream();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _groupStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No groups found.'));
                      }

                      final groups = snapshot.data!.docs.where((doc) {
                        final name = doc['name'].toString().toLowerCase();
                        // If searching, match by name
                        if (_searchQuery.isNotEmpty) {
                          return name.contains(_searchQuery.toLowerCase());
                        }
                        // Otherwise, ensure only groups the user is in are displayed
                        return doc['members'].contains(currentUserId);
                      }).toList();

                      return ListView.builder(
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          final isMember = group['members'].contains(currentUserId);
                          return ListTile(
                            title: Text(group['name']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isMember) ...[
                                  
                                  SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      Icons.double_arrow_outlined,
                                      color: Colors.green,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => GroupChatScreen(
                                            groupId: group.id, // Pass group ID to chat screen
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ] else ...[
                                  IconButton(
                                    icon: Icon(
                                      Icons.group_add_outlined,
                                      color: Colors.green,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => GroupDetailsScreen(
                                            groupId: group.id, // Pass group ID to chat screen
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ]
                              ],
                            ),
                          );
                        },
                      );
                    },
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
                icon: const Icon(Icons.groups_3, size: 30),
                color: Colors.white,
                
                onPressed: () {
                 
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>  GroupListScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_outlined, size: 30),
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
     
    );
  }
}
