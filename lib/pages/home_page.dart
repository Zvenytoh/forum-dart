import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum'),
        actions: [
          IconButton(
            icon: const Icon(Icons.login),
            onPressed: () => Navigator.pushNamed(context, '/login'),
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => Navigator.pushNamed(context, '/register'),
          ),
        ],
      ),
      body: const Center(
        child: Text('Bienvenue sur le Forum!'),
      ),
    );
  }
}