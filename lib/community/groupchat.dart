import 'package:brilnix/community/view_pdf.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;

  const GroupChatScreen({super.key, required this.groupId});

  @override
  GroupChatScreenState createState() => GroupChatScreenState();
}

class GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String groupName = "Loading...";
  bool isBlocked = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userName;
  String? email;

  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        setState(() {
          email = userSnapshot['email'] ?? currentUser.email ?? "No Email";
          userName = userSnapshot['name'] ?? "No Name";
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  Future<void> _fetchGroupDetails() async {
    final groupDoc =
        await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get();
    if (groupDoc.exists) {
      setState(() {
        groupName = groupDoc['name'];
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (isBlocked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You have blocked this group.")),
        );
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null || text.trim().isEmpty) return;
    _messageController.clear();

    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).collection('messages').add({
      'text': text,
      'senderId': user.uid,
      'senderName': userName ?? 'Anonymous',
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendFile() async {
    if (isBlocked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You have blocked this group.")),
        );
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in.")),
        );
      }
      return;
    }

    // Allow only PDF files
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // Ensure file bytes are loaded
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;

      // Ensure the file has valid bytes
      if (file.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to read the file. Please try again.")),
          );
        }
        return;
      }

      final fileName = file.name;

      try {
        // Upload the file to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('group_files/${widget.groupId}/$fileName');

        final uploadTask = storageRef.putData(file.bytes!);
        final snapshot = await uploadTask;

        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Save the file details in Firestore
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('messages')
            .add({
          'fileUrl': downloadUrl,
          'fileName': fileName,
          'senderId': user.uid,
          'senderName': user.displayName ?? 'Anonymous',
          'type': 'file',
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("PDF uploaded successfully.")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to upload PDF. Error: $e")),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No file selected.")),
        );
      }
    }
  }

  void _showGroupInfo() async {
    final groupDoc =
        await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get();
    if (!groupDoc.exists) return;

    final members = List<String>.from(groupDoc['members'] ?? []);
    final adminId = groupDoc['adminId'];

    // Fetch the member details (names)
    List<Map<String, String>> memberDetails = [];
    for (String memberId in members) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(memberId).get();
      if (userDoc.exists) {
        final memberName = userDoc['name'];
        memberDetails.add({
          'id': memberId,
          'name': memberName,
        });
      }
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          children: [
            ListTile(
              title: Text("Group Name: ${groupDoc['name']}"),
            ),
            ListTile(
              title: Text("Group Description: ${groupDoc['description']}"),
            ),
            ListTile(
              title: const Text("Members"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: memberDetails
                    .map((member) => Text(
                          member['name']! + (member['id'] == adminId ? " (Admin)" : ""),
                        ))
                    .toList(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text("Exit Group"),
              onTap: () async {
                Navigator.pop(context);

                // Update the members array by removing the current user
                await FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId)
                    .update({
                  'members': FieldValue.arrayRemove([FirebaseAuth.instance.currentUser!.uid]),
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text("Block Group"),
              onTap: () {
                setState(() {
                  // Block logic can be added here.
                  FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({
                    'blockedGroups': FieldValue.arrayUnion([widget.groupId]),
                  });
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(
          groupName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showGroupInfo,
          ),
        ],
        elevation: 4,
        shadowColor: Colors.deepPurple.withOpacity(0.5),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

               return ListView.builder(
  controller: _scrollController,
  reverse: true,
  itemCount: messages.length + 1,
  itemBuilder: (context, index) {
    if (index == messages.length) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Divider(color: Colors.grey[400]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'User joined/left the group',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    final message = messages[index];
    final type = message['type'];
    final isFile = type == 'file';
    final isCurrentUser =
        message['senderId'] == FirebaseAuth.instance.currentUser?.uid;

    return GestureDetector(
      onLongPress: () async {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // Allow deletion only if the message belongs to the current user
  if (message['senderId'] == currentUserId) {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Cancel
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Confirm
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .doc(message.id) // Use the message document ID
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted successfully')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You can only delete your own messages')),
    );
  }
},

      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Align(
          alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              gradient: isCurrentUser
                  ? LinearGradient(
                      colors: [
                        Colors.deepPurple[300]!,
                        Colors.deepPurple[400]!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.grey[300]!,
                        Colors.grey[400]!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(10),
            child: isFile
                ? GestureDetector(
                    onTap: () {
                      // Open the file (PDF) in a new screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfViewerScreen(
                            pdfName: message['fileName'],
                            pdfUrl: message['fileUrl'],
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.red),
                        const SizedBox(width: 10),
                        Text(
                          message['fileName'],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  )
                : Text(
                    message['text'] ?? '',
                    style: const TextStyle(color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  },
);
},
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.deepPurple),
                  onPressed: _sendFile,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        hintText: 'message...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_messageController.text),
                  child: const CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}