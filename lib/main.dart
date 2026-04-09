import 'package:flutter/material.dart';
import 'package:flutter_carrot_market/pages/app.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Carrot Market',
      theme: ThemeData(
        primaryColor: Colors.white,
        primarySwatch: Colors.orange,
      ),
      home: const App(),
    );
  }
}
