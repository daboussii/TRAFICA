import 'package:flutter/material.dart';
import 'package:traffic/const/constant.dart' as constants;
import 'package:traffic/model/menu_model.dart';
import 'package:traffic/widgets/maps.dart';
import 'alerte.dart';
import 'package:traffic/login.dart';
import 'package:traffic/dashbard.dart';
import 'package:traffic/widgets/camera.dart';

class SideMenuWidget extends StatefulWidget {
  final int initialIndex;
  final Function(int)? onItemSelected;

  const SideMenuWidget({
    super.key,
    this.initialIndex = 0,
    this.onItemSelected,
  });

  @override
  State<SideMenuWidget> createState() => _SideMenuWidgetState();
}

class _SideMenuWidgetState extends State<SideMenuWidget> {
  late int selectedIndex;

  // Simuler une alerte (à remplacer plus tard par Firebase)
  bool hasAlert = true;

  final mainMenu = [
    MenuModel(icon: Icons.home, title: 'Dashboard'),
    MenuModel(icon: Icons.camera_alt, title: 'Camera'),
    MenuModel(icon: Icons.location_on, title: 'Maps'),
    MenuModel(icon: Icons.warning, title: 'Alerts'),
  ];

  final signOutItem = MenuModel(icon: Icons.logout, title: 'SignOut');

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      color: const Color.fromARGB(255, 253, 252, 251),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.only(top: 40, bottom: 14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [],
              ),
              child: Image.asset(
                'icons/logo.png',
                width: 150,
                height: 130,
                fit: BoxFit.contain,
                semanticLabel: 'Traffic Management Logo',
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading logo: $error');
                  return const Icon(
                    Icons.traffic,
                    size: 80,
                    color: Colors.grey,
                  );
                },
              ),
            ),
          ),
          // Main menu items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: mainMenu.length,
              itemBuilder: (context, index) => _buildMenuEntry(index),
            ),
          ),
          // Sign out button at the bottom
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildMenuEntry(mainMenu.length),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuEntry(int index) {
    final isSelected = selectedIndex == index;
    final item = index < mainMenu.length ? mainMenu[index] : signOutItem;
    final isSignOut = index == mainMenu.length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: AnimatedScaleButton(
        isSelected: isSelected,
        onTap: () => _handleItemClick(index, context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? constants.selectionColor.withOpacity(0.8)
                : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.05),
                blurRadius: 4,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: isSignOut
                    ? const Color.fromARGB(255, 6, 6, 6)
                    : isSelected
                        ? Colors.black
                        : (index == 3 && hasAlert
                            ? Colors.red
                            : const Color.fromARGB(255, 44, 43, 43)),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    color: isSignOut
                        ? const Color.fromARGB(255, 6, 6, 6)
                        : isSelected
                            ? Colors.black
                            : const Color.fromARGB(255, 44, 43, 43),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleItemClick(int index, BuildContext context) {
    if (!mounted) return;

    setState(() => selectedIndex = index);

    if (widget.onItemSelected != null) {
      widget.onItemSelected!(index);
    }

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  CameraPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => GoogleMapScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AlertePage()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        break;
    }
  }
}

class AnimatedScaleButton extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  const AnimatedScaleButton({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.child,
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
        if (mounted) {
          setState(() {
            _scale = 0.95;
          });
        }
      },
      onTapUp: (_) {
        if (mounted) {
          setState(() {
            _scale = 1.0;
          });
        }
        widget.onTap();
      },
      onTapCancel: () {
        if (mounted) {
          setState(() {
            _scale = 1.0;
          });
        }
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}