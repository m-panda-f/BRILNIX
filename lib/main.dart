import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';
import 'authentication/loginn.dart';
import 'authentication/signup.dart';
import 'authentication/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      showSemanticsDebugger: false,
      title: "BRILNIX",
      home: AuthChecker(),
    );
  }
}

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return VideoFeedPage();
    } else {
      return const AuthPage();
    }
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false; // Disable back button on home screen
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF32E4F0),
          title: const Text("BRILNIX"),
          
        ),
      ),
    );
  }
}

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
      
        child: 
         Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center the text vertically
          crossAxisAlignment: CrossAxisAlignment.center, // Center the text horizontally
          children: [
            const SizedBox(height: 200,),
            const Text(
              "BRILNIX",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 44.0, // Adjust the font size as needed
                fontWeight: FontWeight.bold, // Makes the text bold
                fontStyle: FontStyle.italic, // Adds an italic style to the text
                color: Colors.deepPurple,

  
                 // Specify your custom font
              ),
            ),
            const SizedBox(height: 200), // Space between text and buttons
            Column(
              mainAxisSize: MainAxisSize.min, // Use minimum space for the buttons
              children: [
                const SizedBox(height: 100,),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0x00AB49CF),
                    padding: const EdgeInsets.symmetric(horizontal: 122, vertical: 15),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LogIn()),
                    );
                  },
                  child: const Text("Login"),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 210, 175, 164),
                    padding: const EdgeInsets.symmetric(horizontal: 118, vertical: 15),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUp()),
                    );
                  },
                  child: const Text("Sign Up"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
