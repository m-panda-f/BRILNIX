import 'package:animate_do/animate_do.dart';
import 'package:brilnix/profile/profile.dart';
import 'package:brilnix/templates/upload_video.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Color> gradientColors;
  final bool showUploadButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.gradientColors = const [Color(0xFF7F00FF), Color(0xFFE100FF)],
    this.showUploadButton = false, // Default is false
  });

  @override
  CustomAppBarState createState() => CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CustomAppBarState extends State<CustomAppBar> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userName;
  String? email;
  String? _profilePictureUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadProfilePicture();
  }

  Future<void> _fetchUserData() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      setState(() {
        email = userSnapshot['email'] ?? currentUser.email ?? "No Email";
        userName = userSnapshot['name'] ?? "No Name";
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, // Remove the default back button
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Row(
        children: [
          FadeInLeft(
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  colors: [Colors.cyanAccent, Colors.lightBlueAccent],
                ).createShader(bounds);
              },
              child: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          const Spacer(),
          if (widget.showUploadButton)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UploadVideoPage()),
                );
              },
              child: Bounce(
                infinite: false,
                child: const Icon(
                  Icons.upload_file,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      elevation: 5,
      actions: [
        if (userName != null && email != null)
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _profilePictureUrl != null
                      ? CircleAvatar(
                          radius: 22,
                          backgroundImage: NetworkImage(_profilePictureUrl!),
                          backgroundColor: Colors.transparent,
                        )
                      : const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey,
                          child: Icon(
                            Icons.account_circle,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(
                      email: email!,
                      userName: userName!,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}