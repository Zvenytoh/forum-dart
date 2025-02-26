import 'package:flutter/material.dart';
import 'package:myapp/pages/forum_page.dart';
import 'package:myapp/pages/home_page.dart';
import 'package:myapp/pages/login_page.dart';
import 'package:myapp/pages/new_message_page.dart';
import 'package:myapp/pages/profil.dart';
import 'package:myapp/pages/register_page.dart';

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
        '/profil': (context) => const ProfilePage(),
      },
    );
  }
}