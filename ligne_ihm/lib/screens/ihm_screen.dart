import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/ordre_fabrication.dart';
import '../services/websocket_service.dart';
import 'login_screen.dart';

class IhmScreen extends StatefulWidget {
  final User user;
  final int poste;
  final String serverIp;

  IhmScreen({
    required this.user,
    required this.poste,
    required this.serverIp,
  });

  @override
  _IhmScreenState createState() => _IhmScreenState();
}

class _IhmScreenState extends State<IhmScreen> {
  late WebSocketService _wsService;
  bool _isConnected = false;
  
  String _cartId = '-';
  OrdreFabrication? _currentOf;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initWebSocket();
    _startTimer();
  }

  void _initWebSocket() {
    _wsService = WebSocketService(
      serverIp: widget.serverIp,
      poste: widget.poste,
      user: widget.user,
      onConnectionStatus: (status) {
        if(mounted) setState(() => _isConnected = status);
      },
      onNouveauChariot: (tagId, ofData) {
        if(mounted) {
           setState(() {
            _cartId = tagId;
            _currentOf = ofData;
            _elapsedSeconds = 0; // Reset timer when new cart arrives
           });
        }
      },
      onChangementPoste: () {
        if(mounted) {
           setState(() {
            _cartId = '-';
            _currentOf = null;
            _elapsedSeconds = 0;
           });
        }
      },
      onAndonAlert: _showAndonDialog,
      onSequenceError: _showSequenceError,
    );

    _wsService.connect();
  }

  void _showAndonDialog(int poste, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('⚠️ Alerte Andon'),
          ],
        ),
        content: Text('$message (Poste $poste)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('D’ACCORD'),
          ),
        ],
      ),
    );
  }

  void _showSequenceError(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('ERREUR SÉQUENCE'),
          ],
        ),
        content: Text(message, style: TextStyle(fontSize: 18)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context),
            child: Text('COMPRIS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted && _cartId != '-' && _currentOf != null) {
        setState(() {
          if (_elapsedSeconds < _currentOf!.tempsAlloueSec) {
            _elapsedSeconds++;
          }
        });
      }
      _startTimer();
    });
  }

  void _triggerAndon() {
    _wsService.sendAndon();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Andon déclenché. Le superviseur a été prévenu.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _validateStep() {
    if (_isConnected && _cartId != '-' && _currentOf != null) {
      _wsService.sendValidation(_cartId, _currentOf!.numeroOf);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OF ${_currentOf!.numeroOf} validé.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _logout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  void dispose() {
    _wsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int maxTime = _currentOf?.tempsAlloueSec ?? 60;
    double progress = maxTime > 0 ? (_elapsedSeconds / maxTime).clamp(0.0, 1.0) : 0.0;
    String variantLabel = _currentOf?.variante ?? '-';
    String ofLabel = _currentOf?.numeroOf ?? 'Aucun OF';
    List<String> instructionsList = _currentOf?.etapes ?? ['En attente d\'un chariot...'];

    return Scaffold(
      backgroundColor: Color(0xFFE5E9F0),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 800),
            margin: EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(36),
              ),
              elevation: 8,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(Icons.memory, color: Colors.blue[800], size: 30),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Poste ${widget.poste}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person, color: Colors.blue[800]),
                              SizedBox(width: 8),
                              Text(
                                '${widget.user.prenom} ${widget.user.nom}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                _isConnected ? Icons.wifi : Icons.wifi_off,
                                color: _isConnected ? Colors.green : Colors.red,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        IconButton(
                           icon: Icon(Icons.logout, color: Colors.red[800]),
                           tooltip: "Déconnexion",
                           onPressed: _logout,
                        )
                      ],
                    ),

                    SizedBox(height: 24),

                    // Info chariot et OF
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.blue[200]!, width: 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.assignment, color: Colors.blue[800], size: 32),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ofLabel,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                  Text(
                                    'Tag: $_cartId',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue[800],
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Text(
                              variantLabel,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Instructions
                    Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: ListView(
                          children: instructionsList.map((etape) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      color: Colors.blue[800], size: 20),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      etape,
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Timer dynamique (déstiné par le composant Node-RED/Odoo)
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.timer, color: Colors.blue[800]),
                                  SizedBox(width: 8),
                                  Text('Temps écoulé Allocation OF : ${maxTime}s'),
                                ],
                              ),
                              Text(
                                '${_elapsedSeconds}s / ${maxTime}s',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: progress > 0.9 ? Colors.red : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress > 0.8 ? Colors.red : Colors.green,
                              ),
                              minHeight: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Boutons d'Action Validation & Andon
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[100],
                              foregroundColor: Colors.orange[900],
                              padding: EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _triggerAndon,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.warning_amber_rounded),
                                SizedBox(width: 12),
                                Text(
                                  'ANDON',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[100],
                              foregroundColor: Colors.green[900],
                              padding: EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              // Désactivé si pas connecté ou pas de chariot
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[600],
                            ),
                            onPressed: (_isConnected && _currentOf != null) ? _validateStep : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle),
                                SizedBox(width: 12),
                                Text(
                                  'VALIDER OF',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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

