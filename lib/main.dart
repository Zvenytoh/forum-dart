import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:myapp/pages/search_page.dart';

void main() {
  runApp(const MyApp());
}

const String baseUrl = 'https://s3-4204.nuage-peda.fr/forum/api/';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forum': (context) => const ForumPage(),
        '/newMessage': (context) => const NewMessagePage(),
      },
    );
  }
}