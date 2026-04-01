import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import 'ihm_screen.dart';
import 'settings_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _matriculeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  int? _currentPoste;

  @override
  void initState() {
    super.initState();
    _loadPoste();
  }

  Future<void> _loadPoste() async {
    final poste = await StorageService.getPoste();
    setState(() {
      _currentPoste = poste;
    });
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus(); // Cacher le clavier
    final matricule = _matriculeController.text.trim();
    final password = _passwordController.text.trim();

    if (matricule.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez remplir tous les champs'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await ApiService.login(matricule, password);
      
      if (user != null) {
        // Connexion réussie, redirection vers l'IHM
        final ipServeur = await StorageService.getIpServeur();
        final poste = await StorageService.getPoste();

        if (ipServeur != null && poste != null) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => IhmScreen(
                user: user,
                poste: poste,
                serverIp: ipServeur,
              ),
            ),
          );
        } else {
           throw Exception("Configuration IP/Poste manquante.");
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Matricule ou mot de passe incorrect'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red[900]),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE5E9F0),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Card(
                margin: EdgeInsets.all(20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Container(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.precision_manufacturing, size: 80, color: Colors.blue[800]),
                        SizedBox(height: 10),
                        // Affichage du numéro de poste actuel
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(20)
                          ),
                          child: Text(
                            'Poste ${_currentPoste ?? "?"}',
                            style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Connexion Opérateur',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 30),
                        TextField(
                          controller: _matriculeController,
                          decoration: InputDecoration(
                            labelText: 'Matricule',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                            prefixIcon: Icon(Icons.badge),
                          ),
                        ),
                        SizedBox(height: 15),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                            prefixIcon: Icon(Icons.lock),
                          ),
                          onSubmitted: (_) => _handleLogin(),
                        ),
                        SizedBox(height: 30),
                        _isLoading
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[800],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                minimumSize: Size(double.infinity, 50), // Prendre toute la largeur
                              ),
                              onPressed: _handleLogin,
                              child: Text('Se connecter', style: TextStyle(fontSize: 18)),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Bouton pour accéder à la configuration
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.settings, color: Colors.grey[600], size: 30),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SettingsScreen())
                );
              },
              tooltip: 'Configuration du Poste',
            ),
          )
        ],
      ),
    );
  }
}
