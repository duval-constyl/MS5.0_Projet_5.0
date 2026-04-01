import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/user_model.dart';
import '../models/ordre_fabrication.dart';

// Définition des callbacks pour que l'interface (IhmScreen) puisse réagir
typedef OnNouveauChariotCallback = void Function(String tagId, OrdreFabrication of);
typedef OnChangementPosteCallback = void Function();
typedef OnAndonAlertCallback = void Function(int posteDeclencheur, String message);
typedef OnSequenceErrorCallback = void Function(String message);
typedef OnConnectionStatusCallback = void Function(bool isConnected);

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  
  final String serverIp;
  final int poste;
  final User user;

  // Callbacks
  final OnNouveauChariotCallback onNouveauChariot;
  final OnChangementPosteCallback onChangementPoste;
  final OnAndonAlertCallback onAndonAlert;
  final OnSequenceErrorCallback onSequenceError;
  final OnConnectionStatusCallback onConnectionStatus;

  WebSocketService({
    required this.serverIp,
    required this.poste,
    required this.user,
    required this.onNouveauChariot,
    required this.onChangementPoste,
    required this.onAndonAlert,
    required this.onSequenceError,
    required this.onConnectionStatus,
  });

  void connect() async {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://$serverIp:1880/ws'),
      );

      try {
        await _channel!.ready;
      } catch (e) {
        print('WebSocket ready error: $e');
        _setConnectionStatus(false);
        Future.delayed(Duration(seconds: 3), connect);
        return; // Stop here if connection setup failed
      }

      _setConnectionStatus(true);

      _channel!.stream.listen((message) {
        final data = jsonDecode(message);
        _handleIncomingMessage(data);
      }, onError: (error) {
        print('WebSocket stream error: $error');
        _setConnectionStatus(false);
      }, onDone: () {
        print('WebSocket closed');
        _setConnectionStatus(false);
        // Retry connection mechanism
        Future.delayed(Duration(seconds: 3), connect);
      });

    } catch (e) {
      print('Connection error: $e');
      _setConnectionStatus(false);
      Future.delayed(Duration(seconds: 3), connect);
    }
  }

  void _setConnectionStatus(bool status) {
    if (_isConnected != status) {
      _isConnected = status;
      onConnectionStatus(status);
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'NOUVEAU_CHARIOT':
        // Vérifier si le message nous est destiné
        if (data['poste'] == poste) {
          final tag = data['tag'] ?? '-';
          final ofData = data['instructions'];
          
          if (ofData != null) {
            final of = OrdreFabrication.fromJson(ofData);
            onNouveauChariot(tag, of);
          }
        }
        break;

      case 'CHANGEMENT_POSTE':
        if (data['poste_source'] == poste) {
          onChangementPoste();
        }
        break;

      case 'ANDON':
      case 'ALERTE_ANDON':
        onAndonAlert(data['poste'] ?? 0, data['message'] ?? 'Alerte signalée');
        break;

      case 'ERREUR_SEQUENCE':
        if (data['poste'] == poste) {
          onSequenceError(data['message'] ?? 'Erreur de séquence');
        }
        break;
    }
  }

  void sendValidation(String tagId, String numeroOf) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({
        'type': 'VALIDATION',
        'poste': poste,
        'tag': tagId,
        'of': numeroOf,
        'operateur': '${user.prenom} ${user.nom}',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }));
    }
  }

  void sendAndon() {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({
        'type': 'ANDON',
        'poste': poste,
        'operateur': '${user.prenom} ${user.nom}',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }));
    }
  }

  void dispose() {
    if (_channel != null) {
      _channel!.sink.close();
    }
  }
}
