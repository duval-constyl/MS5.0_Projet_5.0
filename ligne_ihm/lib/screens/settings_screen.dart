import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isInitialSetup;

  const SettingsScreen({Key? key, this.isInitialSetup = false}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _posteController = TextEditingController();
  final _ipController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  bool _isLoading = true;
  bool _isAdminAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final ip = await StorageService.getIpServeur();
    final poste = await StorageService.getPoste();
    
    if (mounted) {
      setState(() {
        _ipController.text = ip ?? '10.67.160.40';
        _posteController.text = poste?.toString() ?? '';
        
        // Si c'est la configuration initiale (vide), pas besoin de mdp admin pour configurer
        if (widget.isInitialSetup) {
           _isAdminAuthenticated = true;
        }
        _isLoading = false;
      });
    }
  }

  void _verifyAdmin() {
    // Mot de passe superviseur statique pour simplifier (à mettre dans une vraie base ensuite)
    if (_adminPasswordController.text == 'admin123') {
      setState(() {
        _isAdminAuthenticated = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Accès administrateur accordé'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mot de passe incorrect'), backgroundColor: Colors.red),
      );
    }
    _adminPasswordController.clear();
  }

  Future<void> _saveSettings() async {
    final ip = _ipController.text.trim();
    final posteStr = _posteController.text.trim();

    if (ip.isEmpty || posteStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez remplir tous les champs'), backgroundColor: Colors.red),
      );
      return;
    }

    final poste = int.tryParse(posteStr);
    if (poste == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le numéro de poste doit être un entier'), backgroundColor: Colors.red),
      );
      return;
    }

    await StorageService.saveIpServeur(ip);
    await StorageService.savePoste(poste);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Configuration sauvegardée'), backgroundColor: Colors.green),
    );

    // Redirection vers le login
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Color(0xFFE5E9F0),
      appBar: widget.isInitialSetup ? null : AppBar(
        title: Text('Configuration Poste'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Center(
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
                    Icon(Icons.settings, size: 80, color: Colors.blue[800]),
                    SizedBox(height: 20),
                    Text(
                      widget.isInitialSetup ? 'Configuration Initiale' : 'Paramétrage',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Définir les paramètres fixes de cette tablette',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 30),

                    if (!_isAdminAuthenticated) ...[
                      // Verrouillage Admin
                      TextField(
                        controller: _adminPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe Superviseur',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        onSubmitted: (_) => _verifyAdmin(),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: _verifyAdmin,
                        child: Text('Déverrouiller', style: TextStyle(fontSize: 18)),
                      ),
                    ] else ...[
                      // Formulaire de configuration
                      TextField(
                        controller: _posteController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Numéro de poste attribué',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                          prefixIcon: Icon(Icons.settings_input_component),
                        ),
                      ),
                      SizedBox(height: 15),
                      TextField(
                        controller: _ipController,
                        decoration: InputDecoration(
                          labelText: 'IP du serveur Central (Node-RED / API)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                          prefixIcon: Icon(Icons.computer),
                        ),
                      ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: _saveSettings,
                        child: Text('Enregistrer et Continuer', style: TextStyle(fontSize: 18)),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
