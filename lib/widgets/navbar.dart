import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Navbar(),
  ));
}

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  CustomNavBar createState() => CustomNavBar();
}

class CustomNavBar extends State<Navbar> {
  // Define a list of functions to handle button presses
  List<VoidCallback> _onTapActions(BuildContext context) => [
    () {
       Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  Helloworld()),
              );
      // Handle medical services button press
    },
    () {
      // Handle school button press
    },
    () {
      Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  Helloworld()),
              );
      // Handle home button press
    },
    () {
      // Handle contacts button press
    },
    () {
      // Handle calendar button press
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text('Navbar'),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        color: const Color(0xFFEB6C96),
        backgroundColor: Colors.white,
        buttonBackgroundColor: const Color(0xFFEB6C96),
        height: 60,
        items: const <Widget>[
          Icon(Icons.medical_services_outlined, size: 30, color: Colors.white),
          Icon(Icons.school_outlined, size: 30, color: Colors.white),
          Icon(Icons.home_outlined, size: 30, color: Colors.white),
          Icon(Icons.contacts_outlined, size: 30, color: Colors.white),
          Icon(Icons.calendar_month_rounded, size: 30, color: Colors.white),
        ],
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
        onTap: (index) {
          // Call the respective function based on the index
          _onTapActions(context)[index]();
        },
      ),
    );
  }
}

class Helloworld extends StatelessWidget {
  const Helloworld({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hello World'),
      ),
      body: const Center(
        child: Text('Hello World'),
      ),
      bottomNavigationBar: Navbar(),
    );
  }
}
