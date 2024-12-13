import 'dart:io';
import 'package:brilnix/profile/pro.dart';
import '../main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  final String userName;
  final String email;

  const ProfilePage({Key? key, required this.email, required this.userName})
      : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _imageFile;
  int _points = 0;
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _profilePictureUrl;
  String _name = '';
  bool _isEditing = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name = widget.userName;
    _loadProfilePicture();
    _fetchUserData();
    _fetchPoints();
  }

  Future<void> _loadProfilePicture() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _profilePictureUrl = doc.data()?['profilePicture'];
        });
      }
    }
  }

  Future<void> _getImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    try {
      final user = _auth.currentUser;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${user!.uid}.jpg');

      final uploadTask = storageRef.putFile(_imageFile!);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'profilePicture': downloadUrl}, SetOptions(merge: true));

      setState(() {
        _profilePictureUrl = downloadUrl;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _updateUserName() async {
    final user = _auth.currentUser;
    if (_nameController.text.isNotEmpty && user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text,
      });
      final videoQuery = await FirebaseFirestore.instance.collection('videos')
      .where('uploader_id', isEqualTo: user.uid)
      .get();

      for (var doc in videoQuery.docs) {
        await doc.reference.update({
          'uploaded_by': _nameController.text,
        });
      }
      final groupsQuery = await FirebaseFirestore.instance
    .collection('groups')
    .where('members', arrayContains: user.uid)
    .get();

for (var groupDoc in groupsQuery.docs) {
  // Access the 'groupIds' subcollection for each group
  final messagesQuery = await groupDoc.reference
      .collection('messages') // Replace 'groupIds' with the actual subcollection name if different
      .where('senderId', isEqualTo: user.uid)
      .get();

  for (var messageDoc in messagesQuery.docs) {
    await messageDoc.reference.update({
      'senderName': _nameController.text,
    });
  }
}

      setState(() {
        _name = _nameController.text;
        _isEditing = false;
      });
    }
  }

  Future<void> _fetchUserData() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      setState(() {
        _name = userSnapshot['name'] ?? "No Name";
      });
    }
  }

  Future<void> _fetchPoints() async {
    final user = _auth.currentUser;
    if (user != null) {
      final videoQuery = await FirebaseFirestore.instance
          .collection('videos')
          .where('uploader_id', isEqualTo: user.uid)
          .get();

      int totalPoints = 0;
      for (var doc in videoQuery.docs) {
        final data = doc.data();
        final int? rating = data['education_rating'] as int?;
        if (rating != null) {
          totalPoints += rating;
        }
      }
      setState(() {
        _points = totalPoints;
      });
    }
  }

  Future<List<QueryDocumentSnapshot>> _getUserVideos() async {
    final user = _auth.currentUser;
    if (user != null) {
      final videoQuery = await FirebaseFirestore.instance
          .collection('videos')
          .where('uploader_id', isEqualTo: user.uid)
          .get();
      return videoQuery.docs;
    }
    return [];
  }

  Future<void> _deleteVideo(String videoId, String storagePath) async {
    try {
      // Delete the video file from Firebase Storage
      await FirebaseStorage.instance.ref(storagePath).delete();

      // Delete the video document from Firestore
      await FirebaseFirestore.instance.collection('videos').doc(videoId).delete();

      setState(() {}); // Refresh the UI after deletion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video deleted successfully')),
      );
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting video file: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting video: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFEB6C96),
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MyApp()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onDoubleTap: _getImageFromGallery,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _profilePictureUrl != null
                        ? NetworkImage(_profilePictureUrl!)
                        : null,
                    backgroundColor: Colors.grey.shade300,
                    child: _profilePictureUrl == null
                        ? const Icon(
                            Icons.account_circle,
                            size: 50,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _isEditing
                          ? Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                        labelText: "Enter new name"),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check),
                                  onPressed: _updateUserName,
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _name,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = true;
                                      _nameController.text = _name;
                                    });
                                  },
                                ),
                              ],
                            ),
                      const SizedBox(height: 8),
                      Text(
                        widget.email,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 30),
                    Text(
                      '$_points Points',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(thickness: 1),
          // Video Grid
          Expanded(
  child: FutureBuilder<List<QueryDocumentSnapshot>>(
    future: _getUserVideos(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4.0,
            mainAxisSpacing: 4.0,
          ),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            var videoData = snapshot.data![index].data() as Map<String, dynamic>;
            var thumbnailUrl = videoData['thumbnail_url'];
            var videoUrl = videoData['video_url'];
            var videoTitle = videoData['title'] ?? 'Untitled Video';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Videof(
                      videoUrl: videoUrl,
                      videoTitle: videoTitle,
                    ),
                  ),
                );
              },
              onLongPress: () async {
                bool? confirmDelete = await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Delete Video'),
                      content: const Text(
                          'Are you sure you want to delete this video?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );

                if (confirmDelete == true) {
                  await _deleteVideo(snapshot.data![index].id, videoData['storage_path']);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  thumbnailUrl,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        );
      } else {
        return const Center(
          child: Text(
            'No videos uploaded yet',
            style: TextStyle(fontSize: 16),
          ),
        );
      }
    },
  ),
),
],
      ),
    );
  }
}
