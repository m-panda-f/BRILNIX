import 'package:brilnix/community/Search_group.dart';
import 'package:brilnix/courses/course.dart';
import 'package:brilnix/home.dart';
import 'package:brilnix/templates/chatbot.dart';
import 'package:brilnix/widgets/header.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ArticleSearchPage extends StatefulWidget {
  @override
  _ArticleSearchPageState createState() => _ArticleSearchPageState();
}

class _ArticleSearchPageState extends State<ArticleSearchPage> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _articles = [];
  bool _isLoading = false;

  // Random search queries
  final List<String> _randomQueries = [
    'machine learning',
    'artificial intelligence',
    'data science',
    'blockchain',
    'quantum computing',
    'natural language processing',
    'cybersecurity',
    'autonomous vehicles',
    'genomics',
    'renewable energy'
  ];

  @override
  void initState() {
    super.initState();
    _fetchRandomArticles(); // Fetch articles on initialization
  }

  Future<void> _fetchArticles([String query = '']) async {
    setState(() {
      _isLoading = true;
      _articles = [];
    });

    try {
      final url = query.isEmpty
          ? 'https://api.semanticscholar.org/graph/v1/paper/search?fields=title,authors,url,publicationDate'
          : 'https://api.semanticscholar.org/graph/v1/paper/search?query=${Uri.encodeComponent(query)}&fields=title,authors,url,publicationDate';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _articles = data['data'] ?? [];
        });
      } else {
        throw Exception('Failed to fetch articles');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRandomArticles() async {
    setState(() {
      _isLoading = true;
      _articles = [];
    });

    try {
      final randomQuery = (_randomQueries..shuffle()).first;

      final url =
          'https://api.semanticscholar.org/graph/v1/paper/search?query=${Uri.encodeComponent(randomQuery)}&fields=title,authors,url,publicationDate';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _articles = data['data'] ?? [];
        });
      } else {
        throw Exception('Failed to fetch articles');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'EXPLORE ARTICLES', showUploadButton: false),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Material(
              elevation: 5,
              shadowColor: Colors.purple.shade200,
              borderRadius: BorderRadius.circular(10),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search articles...',
                  prefixIcon: Icon(Icons.search, color: Colors.purple),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (query) => _fetchArticles(query),
              ),
            ),
          ),
          _isLoading
              ? Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.purple,
                    ),
                  ),
                )
              : Expanded(
                  child: _articles.isEmpty
                      ? Center(
                          child: Text(
                            'No articles found.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _articles.length,
                          itemBuilder: (context, index) {
                            final article = _articles[index];
                            final authorsList = article['authors'] ?? [];
                            final authors =
                                authorsList.map((a) => a['name']).toList();
                            final publicationDate =
                                article['publicationDate'] ?? 'Unknown Date';

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.all(8),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 15),
                                leading: Icon(
                                  Icons.article,
                                  color: Colors.purple,
                                ),
                                title: Text(
                                  article['title'] ?? 'No Title',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 5),
                                    Text(
                                      'Authors: ${authors.take(3).join(', ')}${authors.length > 3 ? ', More...' : ''}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Published: $publicationDate',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: Icon(Icons.open_in_new,
                                    color: Colors.purple),
                                onTap: () async {
                                  final url = article['url'];
                                  if (url != null && await canLaunch(url)) {
                                    await launch(url);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'No URL available for this article')),
                                    );
                                  }
                                },
                                onLongPress: authors.length > 3
                                    ? () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text('All Authors'),
                                              content: SingleChildScrollView(
                                                child: ListBody(
                                                  children: authors
                                                      .map((author) =>
                                                          Text(author))
                                                      .toList(),
                                                ),
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  child: Text('Close'),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF7A1FCA),
        shape: CircularNotchedRectangle(),
        notchMargin: 5.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.groups, size: 30),
              color: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GroupListScreen()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.chat, size: 30),
              color: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.home, size: 30),
              color: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VideoFeedPage()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.article, size: 30),
              color: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ArticleSearchPage()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.school, size: 30),
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
