import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:traffic/const/constant.dart';
import 'package:traffic/screen/main_screen.dart';
import 'package:traffic/util/responsive.dart';
import 'package:traffic/widgets/maps.dart';
import 'package:traffic/widgets/FooterMenu.dart';

class DashboardPrincipale extends StatefulWidget {
  const DashboardPrincipale({super.key});

  @override
  _DashboardPrincipaleState createState() => _DashboardPrincipaleState();
}

class _DashboardPrincipaleState extends State<DashboardPrincipale> {
  int totalVehicles = 0;
  int totalAmbulances = 0;
  DatabaseReference dbRef = FirebaseDatabase.instance.ref('comptage');
  StreamSubscription<DatabaseEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _listenToFirebaseData();
  }

  void _listenToFirebaseData() {
    _subscription = dbRef.onValue.listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      final vehiclesCount = data?['vehicules']?['total'] as int?;
      final ambulancesCount = data?['ambulances']?['total'] as int?;

      setState(() {
        totalVehicles = vehiclesCount ?? 0;
        totalAmbulances = ambulancesCount ?? 0;
      });
    }, onError: (error) {
      print('Firebase error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement des données: $error')),
        );
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            if (isMobile)
              Container(
                color: backgroundColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(children: []),
              ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 10 : 18,
                            vertical: isMobile ? 20 : 40,
                          ),
                          child: Column(
                            children: [
                              isMobile
                                  ? Column(
                                      children:
                                          _buildButtons(context, isMobile),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children:
                                          _buildButtons(context, isMobile),
                                    ),
                              const SizedBox(height: 30),
                              if (isMobile)
                                Column(
                                  children: [
                                    _buildCard(
                                      'Total Vehicles',
                                      '$totalVehicles vehicles today',
                                      Icons.directions_car,
                                    ),
                                    const SizedBox(height: 5),
                                    _buildCard(
                                      'Total Emergency Vehicles',
                                      '$totalAmbulances Emergency Vehicles today',
                                      Icons.local_hospital,
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildCard(
                                      'Total Vehicles',
                                      '$totalVehicles vehicles today',
                                      Icons.directions_car,
                                    ),
                                    const SizedBox(width: 20),
                                    _buildCard(
                                      'Total Emergency Vehicles',
                                      '$totalAmbulances ambulances today',
                                      Icons.local_hospital,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // FooterMenu uniquement pour mobile
            if (isMobile) const FooterMenu(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildButtons(BuildContext context, bool isMobile) {
    final buttonWidth = 200.0;
    final buttonHeight = 50.0;

    return [
      SizedBox(
        width: buttonWidth,
        height: buttonHeight,
        child: AnimatedScaleButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => GoogleMapScreen()),
            );
          },
          color: selectionColor,
          text: 'Open Map',
          textColor: const Color.fromARGB(255, 6, 6, 6),
        ),
      ),
      SizedBox(width: isMobile ? 0 : 20, height: isMobile ? 10 : 0),
      SizedBox(
        width: buttonWidth,
        height: buttonHeight,
        child: AnimatedScaleButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          },
          color: const Color.fromARGB(255, 7, 7, 7),
          text: 'View All Details',
          textColor: const Color.fromARGB(255, 254, 254, 254),
        ),
      ),
    ];
  }

  Widget _buildCard(String title, String subtitle, IconData icon) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 400,
        minWidth: 300,
      ),
      child: Container(
        height: 140,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: title == 'Total Vehicles'
              ? const Color.fromARGB(255, 250, 250, 251).withOpacity(0.8)
              : const Color.fromARGB(255, 253, 252, 252).withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AnimatedIconContainer(
                icon: icon,
                color: title == 'Total Vehicles'
                    ? const Color.fromARGB(255, 7, 7, 7)
                    : const Color(0xFFD32F2F),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedScaleButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color color;
  final String text;
  final Color textColor;

  const AnimatedScaleButton({
    super.key,
    required this.onPressed,
    required this.color,
    required this.text,
    required this.textColor,
  });

  @override
  _AnimatedScaleButtonState createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<AnimatedScaleButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _scale = 0.95;
        });
      },
      onTapUp: (_) {
        setState(() {
          _scale = 1.0;
        });
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() {
          _scale = 1.0;
        });
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.text,
              style: TextStyle(
                color: widget.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedIconContainer extends StatefulWidget {
  final IconData icon;
  final Color color;

  const AnimatedIconContainer({
    super.key,
    required this.icon,
    required this.color,
  });

  @override
  _AnimatedIconContainerState createState() => _AnimatedIconContainerState();
}

class _AnimatedIconContainerState extends State<AnimatedIconContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          widget.icon,
          color: widget.color,
          size: 36,
        ),
      ),
    );
  }
}