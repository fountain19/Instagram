import 'package:flutter/material.dart';
import 'package:instagram/pages/homePage.dart';



void main() async {
  //this widget for accec any method or any thing from main void
  WidgetsFlutterBinding.ensureInitialized();
    runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Instagram',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        dialogBackgroundColor: Colors.black,
        primarySwatch: Colors.grey,
        accentColor: Colors.black,
        cardColor: Colors.white70,
      ),
      home: HomePage(),
    );
  }
}