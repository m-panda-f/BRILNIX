import 'package:brilnix/community/Search_group.dart';
import 'package:brilnix/courses/course.dart';
import 'package:brilnix/templates/articles.dart';

import 'package:brilnix/templates/chatbot.dart';

import 'package:brilnix/widgets/header.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_share/flutter_share.dart';
import 'templates/comment_page.dart';

class VideoFeedPage extends StatefulWidget {
  const VideoFeedPage({Key? key}) : super(key: key);

  @override
  VideoFeedPageState createState() => VideoFeedPageState();
}

class VideoFeedPageState extends State<VideoFeedPage> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<DocumentSnapshot> videos = [];
  VideoPlayerController? _controller;
  int currentIndex = 0;
  String? userName;
  String? email;
  bool showFullDescription = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchUserData();
    _fetchVideos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.pause();
    _controller?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    super.deactivate();
    _controller?.pause(); // Pause the video when navigating away
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _controller?.pause(); // Pause video if the app is not active
    } else if (state == AppLifecycleState.resumed) {
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        _controller?.play(); // Resume video only if on this page
      }
    }
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

  Future<void> _fetchVideos() async {
    try {
      final videoSnapshot = await FirebaseFirestore.instance.collection('videos').get();
      setState(() {
        videos = videoSnapshot.docs..shuffle();
      });
      if (videos.isNotEmpty) {
        _initializeVideo(0);
      }
    } catch (e) {
      debugPrint("Error fetching videos: $e");
    }
  }

  Future<void> _initializeVideo(int index) async {
    try {
      await _controller?.dispose();
      _controller = VideoPlayerController.networkUrl(Uri.parse(videos[index]['video_url']))
        ..initialize().then((_) {
          setState(() {});
          _controller?.setLooping(true);
          _controller?.play();
        });
    } catch (e) {
      debugPrint("Error initializing video: $e");
    }
  }

  void _toggleSound() {
    if (_controller != null) {
      setState(() {
        _controller!.setVolume(_controller!.value.volume == 0 ? 1.0 : 0.0);
      });
    }
  }

  void _toggleDescription() {
    setState(() {
      showFullDescription = !showFullDescription;
    });
  }

  @override
    Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: const CustomAppBar(title: 'BRILO', showUploadButton: true),
        body: videos.isNotEmpty
            ? PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                    showFullDescription = false;
                  });
                  _initializeVideo(index);
                },
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final description = videos[index]['description'] ?? "";
                  final uploadedBy = videos[index]['uploaded_by'] ?? "Unknown";

                  return Stack(
                    children: [
                      Center(
                        child: _controller != null && _controller!.value.isInitialized
                            ? GestureDetector(
                                onTap: () {
                                  if (_controller!.value.isPlaying) {
                                    _controller?.pause();
                                  } else {
                                    _controller?.play();
                                  }
                                },
                                child: AspectRatio(
                                  aspectRatio: _controller!.value.aspectRatio,
                                  child: VideoPlayer(_controller!),
                                ),
                              )
                            : const Center(child: CircularProgressIndicator()),
                      ),

                      // Video Details
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3), // Semi-transparent background
                            borderRadius: BorderRadius.circular(00), // Rounded corners
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                uploadedBy,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),
                              GestureDetector(
                                onTap: _toggleDescription,
                                child: Text(
                                  showFullDescription
                                      ? description
                                      : description.length > 20
                                          ? '${description.substring(0, 20)}... More'
                                          : description,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Action Buttons
                      Positioned(
                        right: 10,
                        bottom: 100,
                        child: Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.comment, color: Color(0xFF515151), size: 30),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CommentPage(videoId: videos[index].id),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            IconButton(
                              icon: const Icon(Icons.share, color: Color(0xFF515151), size: 30),
                              onPressed: () async {
                                await FlutterShare.share(
                                  title: 'Check out this video!',
                                  linkUrl: videos[index]['video_url'],
                                  chooserTitle: 'Share Video',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              )
            : const Center(child: CircularProgressIndicator()),
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
                  _controller?.pause();
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
                  _controller?.pause();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.home, size: 30),
                color: Colors.white,
                onPressed: () {
                  _controller?.pause();
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
                  _controller?.pause();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ArticleSearchPage()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.menu_book_sharp, size: 30),
                color: Colors.white,
                onPressed: () {
                  _controller?.pause();
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
  }}
