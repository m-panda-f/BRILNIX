import 'package:brilnix/community/Search_group.dart';
import 'package:brilnix/home.dart';
import 'package:brilnix/templates/articles.dart';
import 'package:brilnix/templates/chatbot.dart';
import 'package:brilnix/widgets/header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'course_deatils.dart';

class CourseListPage extends StatefulWidget {
  const CourseListPage({Key? key}) : super(key: key);

  @override
  _CourseListPageState createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  int _userPoints = 0; // Variable to store user points
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchPoints(); // Fetch the user points when the page is initialized
  }

  // Fetch user points based on the existing logic
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
        _userPoints = totalPoints; // Update the points
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:const CustomAppBar(title: 'Courses', showUploadButton: false),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('Courses').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No courses available'));
          }

          final courses = snapshot.data!.docs;

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Number of items per row
              crossAxisSpacing: 8.0, // Horizontal spacing between grid items
              mainAxisSpacing: 8.0, // Vertical spacing between grid items
              childAspectRatio: 3 / 4, // Adjust this for aspect ratio of items
            ),
            padding: const EdgeInsets.all(8.0),
            itemCount: courses.length,
itemBuilder: (context, index) {
  final course = courses[index];
  final courseTitle = course['courseTitle'] ?? 'No Title';
  final courseDescription = course['courseDescription'] ?? 'No Description';
  final courseImage = course['courseImage']; // Image URL field
  final coursePoints = course['coursePoints'] ?? 0; // Points required for the course

  // Check if the user has enough points to access the course
  final isAccessible = _userPoints >= coursePoints;

  return GestureDetector(
    onTap: isAccessible
        ? () {
            // Navigate to course details page if accessible
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseDetailsPage(courseId: course.id),
              ),
            );
          }
        : () {
            // Show AlertDialog if the course is not accessible
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Insufficient Points'),
                  content: const Text('You do not have enough points to access this course.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          }, // Disable navigation if not accessible
    child: Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: (courseImage != null && courseImage is String && courseImage.isNotEmpty)
                    ? Image.network(
                        courseImage,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback for invalid image URLs
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300], // Placeholder color
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.black54,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              courseTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4.0),
            Text(
              courseDescription,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8.0),
            Text(
              'Required Points: $coursePoints',
              style: TextStyle(
                fontSize: 14,
                color: isAccessible ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    ),
  );
},
          );
        },
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
                  Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ArticleSearchPage()),
                );
                  
                },
              ),
              IconButton(
                icon: const Icon(Icons.menu_book_rounded, size: 30),
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CourseListPage()),
                  );
                },
              ),
            ],
          ),
        ),
     
    );
    
  }
}