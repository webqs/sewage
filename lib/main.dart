import 'package:flutter/material.dart';

import 'home_screen.dart'; // It's crucial that this path is correct

// This is the starting point of your entire app.
// Flutter looks for this function in this specific file.
void main() {
  runApp(const MyApp());
}

// MyApp is the root widget that sets up the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      // It tells the app to show the HomeScreen widget first.
      home: HomeScreen(),
    );
  }
}
