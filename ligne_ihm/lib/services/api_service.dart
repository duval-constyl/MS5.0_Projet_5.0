import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'storage_service.dart';

class ApiService {
  // L'URL du backend FastAPI. En production, cela viendrait potentiellement aussi de la configuration
  // Pour l'instant on suppose que le backend tourne sur le même serveur que Node-RED (port 8000 par défaut pour FastAPI)
  
  static Future<String> getBaseUrl() async {
     final ip = await StorageService.getIpServeur();
     if (ip == null || ip.isEmpty) {
       throw Exception("IP du serveur non configurée");
     }
     return "http://$ip:8000/api";
  }

  static Future<User?> login(String matricule, String password) async {
    try {
      final baseUrl = await getBaseUrl();
      final url = Uri.parse('$baseUrl/login');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'matricule': matricule,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user'] != null) {
          return User.fromJson(data['user']);
        }
      }
      return null; // Login failed (e.g., 401 Unauthorized)
    } catch (e) {
      print('Erreur de connexion API : $e');
      throw Exception('Impossible de se connecter au serveur d\'authentification. Vérifiez le réseau.');
    }
  }
}
