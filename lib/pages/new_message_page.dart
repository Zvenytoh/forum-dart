import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NewMessagePage extends StatefulWidget {
  const NewMessagePage({super.key});

  @override
  _NewMessagePageState createState() => _NewMessagePageState();
}

class _NewMessagePageState extends State<NewMessagePage> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _contenuController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  final ApiService _apiService = ApiService();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _apiService.sendMessage(
        _titreController.text,
        _contenuController.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } on HttpException catch (e) {
      setState(() => _errorMessage = e.toString());
    } catch (e) {
      setState(() => _errorMessage = 'Erreur inconnue');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau message')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _titreController,
                  decoration: const InputDecoration(labelText: 'Titre'),
                  validator: (value) => value!.isEmpty ? 'Titre requis' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _contenuController,
                  decoration: const InputDecoration(labelText: 'Contenu'),
                  maxLines: 5,
                  validator: (value) => value!.isEmpty ? 'Contenu requis' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Envoyer'),
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}