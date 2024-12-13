import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_share/flutter_share.dart';
import '../templates/comment_page.dart';

class Videof extends StatefulWidget {
  final String? videoUrl;
  final String? videoTitle;

  const Videof({super.key, this.videoUrl, this.videoTitle});

  @override
  VideoFeedPageState createState() => VideoFeedPageState();
}

class VideoFeedPageState extends State<Videof> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  List<DocumentSnapshot> videos = [];
  VideoPlayerController? _controller;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  VideoPlayerController? _nextController;
  int currentIndex = 0;
  String? userName;
  String? email;
  bool showFullDescription = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchUserData();
    if (widget.videoUrl != null && widget.videoTitle != null) {
      _initializeVideoFromParams();
    } else {
      _fetchUserVideos();
    }
    
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _nextController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller?.pause();
    } else if (state == AppLifecycleState.resumed && _controller != null) {
      _controller?.play();
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
        email = userSnapshot['email'] ?? currentUser.email ?? "No Email";
        userName = userSnapshot['name'] ?? "No Name";
      });
    }
  }

 

  Future<void> _fetchUserVideos() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      QuerySnapshot videoSnapshot = await FirebaseFirestore.instance
          .collection('videos')
          .where('uploaded_by', isEqualTo: userName)
          .get();

      setState(() {
        videos = videoSnapshot.docs..shuffle();
      });

      if (videos.isNotEmpty) {
        _initializeVideo(0);
        if (videos.length > 1) {
          _preloadNextVideo(1);
        }
      }
    }
  }

  Future<void> _initializeVideoFromParams() async {
    if (widget.videoUrl != null) {
      _controller = VideoPlayerController.network(widget.videoUrl!)
        ..initialize().then((_) {
          setState(() {});
          _controller?.setLooping(true);
          _controller?.play();
        });
    }
  }

  Future<void> _initializeVideo(int index) async {
    if (_controller != null) {
      await _controller?.dispose();
    }

    _controller = VideoPlayerController.network(videos[index]['video_url'])
      ..initialize().then((_) {
        setState(() {});
        _controller?.setLooping(true);
        _controller?.play();
      });
  }

  Future<void> _preloadNextVideo(int index) async {
    if (_nextController != null) {
      await _nextController?.dispose();
    }

    _nextController = VideoPlayerController.network(videos[index]['video_url'])
      ..initialize();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BRILO',
          style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.bold),
        ),
       
        
      ),
      body: videos.isNotEmpty
          ? PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: videos.length,
              itemBuilder: (context, index) {
                String description = videos[index]['description'] ?? "";
                return Stack(
                  children: [
                    _controller != null && _controller!.value.isInitialized
                        ? VideoPlayer(_controller!)
                        : const Center(child: CircularProgressIndicator()),
                    
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            videos[index]['uploaded_by'] ?? "Unknown",
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: _toggleDescription,
                            child: Text(
                              showFullDescription
                                  ? description
                                  : description.length > 50
                                      ? '${description.substring(0, 50)}... More'
                                      : description,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 20,
                      bottom: 80,
                      child: Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.comment, color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CommentPage(videoId: videos[index].id),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.share, color: Colors.white),
                            onPressed: () async {
                              await FlutterShare.share(
                                title: 'Check out this video!',
                                linkUrl: videos[index]['video_url'],
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
    );
  }
}
