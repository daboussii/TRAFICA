import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:traffic/const/constant.dart';
import 'package:traffic/screen/main_screen.dart'; // Importez MainScreen
import 'package:traffic/widgets/alerte.dart';
import 'package:traffic/widgets/camera.dart';
import 'package:traffic/widgets/dashboard_widget.dart';
import 'package:traffic/widgets/maps.dart'; // Importez GoogleMapScreen
import 'package:traffic/dashbard.dart'; // Importez DashboardPrincipale

class FooterMenu extends StatefulWidget {
  const FooterMenu({super.key});

  @override
  State<FooterMenu> createState() => _FooterMenuState();
}

class _FooterMenuState extends State<FooterMenu> with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isDisposed = false;
  String _lastWords = '';
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (!_isDisposed && mounted) {
          setState(() {
            _isListening = status == 'listening';
          });
        }
      },
      onError: (error) {
        print('Error: $error');
        if (!_isDisposed && mounted) {
          setState(() {
            _isListening = false;
          });
        }
      },
    );

    if (!available && !_isDisposed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La reconnaissance vocale n\'est pas disponible')),
      );
    }
  }

  void _startListening() async {
    if (_isDisposed || !mounted) return;

    _lastWords = '';
    if (!_isDisposed && mounted) {
      setState(() {
        _isListening = true;
      });
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    }

    try {
      await _speech.listen(
        onResult: (result) {
          if (!_isDisposed && mounted) {
            setState(() {
              _lastWords = result.recognizedWords;
            });
            _processVoiceCommand(_lastWords);
          }
        },
        localeId: 'fr_FR',
        listenFor: const Duration(seconds: 5),
        cancelOnError: true,
        partialResults: true,
      );
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  void _stopListening() async {
    if (_isDisposed || !mounted) return;

    try {
      await _speech.stop();
      if (!_isDisposed && mounted) {
        setState(() {
          _isListening = false;
        });
        _controller.stop();
        _controller.value = 1.0;
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  void _handleItemClick(int index, BuildContext context) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>  CameraPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GoogleMapScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AlertePage()),
        );
        break;
        case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
        break;
      default:
        break;
    }
  }

  void _processVoiceCommand(String command) {
    if (_isDisposed || !mounted) return;

    command = command.toLowerCase();

    if (command.contains('détails') || command.contains('détails')) {
      print('Action: Naviguer vers MainScreen');
      _handleItemClick(0, context);
    } else if (command.contains('caméra') || command.contains('camera')) {
      print('Action: Naviguer vers CameraPage');
      _handleItemClick(1, context);
    } else if (command.contains('maps') || command.contains('maps') || command.contains('map')) {
      print('Action: Naviguer vers GoogleMapScreen');
      _handleItemClick(2, context);
    } else if (command.contains('alerte') || command.contains('alert')) {
      print('Action: Naviguer vers AlertePage');
      _handleItemClick(3, context);
    } else if (command.contains('dashboard') || command.contains('dashboard')) {
      print('Action: Naviguer vers AlertePage');
      _handleItemClick(4, context);
    } 
  }

  @override
  void dispose() {
    _isDisposed = true;
    _speech.stop();
    _speech.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, -3),
                ),
              ],
            ),
          ),
          Positioned(
            top: -20,
            child: GestureDetector(
              onTap: () {
                if (_isListening) {
                  _stopListening();
                } else {
                  _startListening();
                }
              },
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isListening ? _controller.value * 0.1 + 1.0 : 1.0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selectionColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.black,
                            size: 36,
                          ),
                        ),
                        if (!_isListening)
                          CustomPaint(
                            painter: DiagonalLinePainter(),
                            size: const Size(60, 60),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      const Offset(15, 45),
      const Offset(45, 15),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}