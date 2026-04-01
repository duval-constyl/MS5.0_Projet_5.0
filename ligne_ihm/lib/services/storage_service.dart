import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String keyIpServeur = 'ip_serveur';
  static const String keyPoste = 'poste';

  // Récupérer l'IP du serveur
  static Future<String?> getIpServeur() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyIpServeur);
  }

  // Sauvegarder l'IP du serveur
  static Future<void> saveIpServeur(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyIpServeur, ip);
  }

  // Récupérer le numéro de poste
  static Future<int?> getPoste() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyPoste);
  }

  // Sauvegarder le numéro de poste
  static Future<void> savePoste(int poste) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyPoste, poste);
  }
  
  // Vérifier si la tablette est configurée (IP et Poste présents)
  static Future<bool> isConfigured() async {
    final ip = await getIpServeur();
    final poste = await getPoste();
    return ip != null && ip.isNotEmpty && poste != null;
  }
}
