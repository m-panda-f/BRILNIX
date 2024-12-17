import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class CourseDetailsPage extends StatefulWidget {
  final String courseId;

  const CourseDetailsPage({super.key, required this.courseId});

  @override
  CourseDetailsPageState createState() => CourseDetailsPageState();
}

class CourseDetailsPageState extends State<CourseDetailsPage> {
  DocumentSnapshot? courseData;
  bool _isDescriptionExpanded = false;
  int _selectedVideoIndex = 0;
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _isLoadingVideo = false;

  @override
  void initState() {
    super.initState();
    _fetchCourseData();
  }

  Future<void> _fetchCourseData() async {
    try {
      final data = await FirebaseFirestore.instance
          .collection('Courses')
          .doc(widget.courseId)
          .get();

      if (!data.exists) {
        throw Exception('Course not found');
      }

      setState(() {
        courseData = data;
      });

      // Initialize the first video if available
      if (courseData!['videos'] != null &&
          courseData!['videos'] is List &&
          (courseData!['videos'] as List).isNotEmpty) {
        _initializeVideo(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching course: $e'),
          ),
        );
      }
    }
  }

  Future<void> _initializeVideo(int index) async {
    try {
      setState(() {
        _isLoadingVideo = true;
      });

      await _controller?.dispose();
      final videos = List<Map<String, dynamic>>.from(courseData!['videos']);
      final videoUrl = videos[index]['videoLink'];

      if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')) {
        _openVideo(videoUrl);
      } else {
        _controller = VideoPlayerController.network(videoUrl)
          ..initialize().then((_) {
            setState(() {
              _isPlaying = true;
              _isLoadingVideo = false;
            });
            _controller?.setLooping(true);
            _controller?.play();
          });
      }
    } catch (e) {
      setState(() {
        _isLoadingVideo = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error initializing video: $e")),
      );
    }
  }

  Future<void> _openVideo(String videoUrl) async {
  final Uri encodedUrl = Uri.parse(videoUrl); // Ensure the URL is safely parsed
  if (await canLaunchUrl(encodedUrl)) {
    await launchUrl(encodedUrl, mode: LaunchMode.externalApplication);
  } else {
    // Show dialog to ask user for fallback
    _showOpenInBrowserDialog(videoUrl);
  }
}

Future<void> _showOpenInBrowserDialog(String videoUrl) async {
  if (!mounted) return; // Safety check for widget state
  final shouldOpen = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Unable to Play Video'),
        content: const Text(
            'We couldn\'t play the video in the app. Would you like to open it in Chrome or your browser instead?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false); // User cancels
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true); // User agrees
            },
            child: const Text('Open in Browser'),
          ),
        ],
      );
    },
  );

  if (shouldOpen == true) {
    // Attempt to open in browser as a fallback
    final browserUrl = Uri.parse(videoUrl);
    try {
      await launchUrl(browserUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open video in the browser.'),
        ),
      );
    }
  }
}



  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildDrawer(List<Map<String, dynamic>> videos) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
              ),
            ),
            child: const Text(
              'Course Videos',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
          ...videos.asMap().entries.map((entry) {
            final index = entry.key;
            final video = entry.value;

            return ListTile(
              leading: const Icon(Icons.play_circle_fill, color: Colors.blue),
              title: Text(video['videoTitle']),
              tileColor: _selectedVideoIndex == index
                  ? Colors.blueAccent.withOpacity(0.2)
                  : null,
              onTap: () {
                Navigator.pop(context); // Close the drawer
                setState(() {
                  _selectedVideoIndex = index;
                });
                _initializeVideo(index);
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_isLoadingVideo) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: Text("No video available"));
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                setState(() {
                  if (_isPlaying) {
                    _controller?.pause();
                  } else {
                    _controller?.play();
                  }
                  _isPlaying = !_isPlaying;
                });
              },
            ),
            IconButton(
              icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
              onPressed: () {
                setState(() {
                  _controller?.setVolume(_isMuted ? 1 : 0);
                  _isMuted = !_isMuted;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Back button functionality
          },
        ),
        title: Text(
          courseData?['courseTitle'] ?? 'Loading...',
          style: const TextStyle(fontSize: 20),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openEndDrawer(); // Open right-side drawer
              },
            ),
          ),
        ],
      ),
      endDrawer: courseData != null
          ? _buildDrawer(
              List<Map<String, dynamic>>.from(courseData!['videos']))
          : null,
      body: courseData != null
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courseData!['courseDescription'],
                    maxLines: _isDescriptionExpanded ? null : 2,
                    overflow: _isDescriptionExpanded
                        ? null
                        : TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isDescriptionExpanded = !_isDescriptionExpanded;
                      });
                    },
                    child: Text(
                      _isDescriptionExpanded ? 'Show Less' : 'Show More',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildVideoPlayer(),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
