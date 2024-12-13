import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:brilnix/home.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';



class UploadVideoPage extends StatefulWidget {
  const UploadVideoPage({Key? key}) : super(key: key);

  @override
  UploadVideoPageState createState() => UploadVideoPageState();
  
}

class UploadVideoPageState extends State<UploadVideoPage> {
  void initState() {
    super.initState();
    _fetchUserData();
  }
  XFile? _videoFileWeb;
  File? _videoFile;
  final String apiKey = 'AIzaSyCf9QA-FCMhL-_2a_em0F2wPmBTbgYg4eY';
  String? _thumbnailPath;
  bool _isUploading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
    String? userName;
  double _uploadProgress = 0.0;
  VideoPlayerController? _videoPlayerController;
  final picker = ImagePicker();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  Future<void> _pickVideo() async {
    try {
      final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          if (kIsWeb) {
            _videoFileWeb = pickedFile;
          } else {
            _videoFile = File(pickedFile.path);
          }
        });

        // Initialize video player
        _videoPlayerController = VideoPlayerController.file(File(pickedFile.path))
          ..initialize().then((_) {
            setState(() {});  // Update UI
          });

        // Generate a default thumbnail
        await _generateThumbnail(pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to pick video: $e")),
        );
      }
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
        userName = userSnapshot['name'] ?? "No Name";
      });
    }
  }

  Future<void> _generateThumbnail(String videoPath) async {
    final thumbnail = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 150,
    );
    setState(() {
      _thumbnailPath = thumbnail;
    });
  }

  Future<void> _selectThumbnail() async {
    if (_videoPlayerController == null || !_videoPlayerController!.value.isInitialized) return;

    final videoPath = _videoFile?.path ?? _videoFileWeb!.path;
    final position = _videoPlayerController!.value.position;

    final thumbnail = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 150,
      timeMs: position.inMilliseconds,
    );

    setState(() {
      _thumbnailPath = thumbnail;
    });
  }

  Future<void> _uploadVideo() async {
  if ((_videoFile == null && _videoFileWeb == null) || _descriptionController.text.isEmpty) return;

  setState(() {
    _isUploading = true;
    
    _uploadProgress = 0.0;
  });

  try {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No user is logged in")),
        );
      }
      return;
    }
    

   
    String videoId = FirebaseFirestore.instance.collection('videos').doc().id;
    FirebaseStorage storage = FirebaseStorage.instance;

    // Prepare the video file for upload
    var videoData = kIsWeb ? await _videoFileWeb!.readAsBytes() : await _videoFile!.readAsBytes();

    // Step 1: Send the video to the Flask backend for classification
    var request = http.MultipartRequest('POST', Uri.parse('https://video-classifier.onrender.com/transcribe'))
      ..files.add(await http.MultipartFile.fromPath('video', _videoFile?.path ?? _videoFileWeb!.path));

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    var result = jsonDecode(responseBody);
    String transcription = result['transcription'] ?? '';

    // Step 2: Send the transcription to the generative AI bot for classification
    String prompt = """
        Determine if the following text is educational. If educational, provide a rating from 1 to 20, 
        where 20 is highly educational. Otherwise, classify as 'Non-Educational'.
        Ensure to give the best possible rating based on the content.
        
        Text: $transcription
        
        Output: 'Educational' with a rating, or 'Non-Educational'.
    """;

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey, // Use your actual API key here
    );

    try {
      final response = await model.generateContent([Content.text(prompt)]);

      // Step 3: Check the classification result from the AI bot
      String botResponse = response.text ?? 'Error: No response from AI.';
      if (botResponse.contains('Non-Educational')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("The video is classified as non-educational. Upload aborted.")),
          );
        }
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Extract rating if educational
      final rating = _extractRatingFromBotResponse(botResponse);
      if (rating == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to classify the video as educational.")),
          );
        }
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Proceed with upload if educational
      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = storage.ref('videos/${userName}/$videoId').putData(videoData);
      } else {
        uploadTask = storage.ref('videos/${userName}/$videoId').putFile(_videoFile!);
      }

      // Show upload progress
      uploadTask.snapshotEvents.listen((event) {
        setState(() {
          _uploadProgress = event.bytesTransferred.toDouble() / event.totalBytes.toDouble();
        });
      });

      var videoUrl = await (await uploadTask).ref.getDownloadURL();

      // Upload thumbnail if exists
      String? thumbnailUrl;
      if (_thumbnailPath != null) {
        final thumbUploadTask = storage.ref('thumbnails/${userName}/$videoId.jpg').putFile(File(_thumbnailPath!));
        thumbnailUrl = await (await thumbUploadTask).ref.getDownloadURL();
      }

      // Store video data in Firestore
      FirebaseFirestore.instance.collection('videos').doc(videoId).set({
        'video_url': videoUrl,
        'thumbnail_url': thumbnailUrl,
        'description': _descriptionController.text,
        'tags': _tagsController.text.split(',').map((tag) => tag.trim()).toList(),
        'comments': [],
        'share_count': 0,
        'uploaded_by': userName,
        'uploader_id': user.uid,
        'education_rating': rating,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video uploaded successfully!")),
        );
      }

      // Clear fields after successful upload
      setState(() {
        _videoFile = null;
        _videoFileWeb = null;
        _descriptionController.clear();
        _tagsController.clear();
        _thumbnailPath = null;
        _isUploading = false;
        _videoPlayerController?.dispose();
        _videoPlayerController = null;
      });

      // Redirect to home page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VideoFeedPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to classify the video: $e")),
        );
      }
      setState(() {
        _isUploading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload video: $e")),
      );
    }
    setState(() {
      _isUploading = false;
    });
  }
}

int? _extractRatingFromBotResponse(String botResponse) {
  final regex = RegExp(r'\d+');
  final match = regex.firstMatch(botResponse);
  if (match != null) {
    return int.tryParse(match.group(0) ?? '');
  }
  return null;
}
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Video")),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (_videoFile != null || _videoFileWeb != null) ...[
                    if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized)
                      Column(
                        children: [
                          AspectRatio(
                            aspectRatio: _videoPlayerController!.value.aspectRatio,
                            child: VideoPlayer(_videoPlayerController!),
                          ),
                          IconButton(
                            icon: const Icon(Icons.photo),
                            onPressed: _selectThumbnail,
                            tooltip: "Capture Thumbnail",
                          ),
                        ],
                      ),
                    if (_thumbnailPath != null) Image.file(File(_thumbnailPath!), height: 100),
                    const SizedBox(height: 20),
                  ],
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: "Video Description",
                      hintText: "Description",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      labelText: "Tags",
                      hintText: "Separate tags with commas",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _pickVideo,
                        child: const Text("Pick Video"),
                      ),
                      ElevatedButton(
                        onPressed: _uploadVideo,
                        child: const Text("Upload Video"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    NumericalProgressIndicator(value: _uploadProgress),
                    const SizedBox(height: 10),
                    const Text(
                      "Uploading...",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                   
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }
}

class NumericalProgressIndicator extends StatelessWidget {
  final double value;

  const NumericalProgressIndicator({Key? key, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      '${(value * 100).toStringAsFixed(1)}%',
      style: const TextStyle(color: Colors.white, fontSize: 18),
    );
  }
}