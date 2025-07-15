import 'package:traffic/const/constant.dart';
import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const CustomCard({super.key, this.color, this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(  // Wrap with SingleChildScrollView
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(8.0),
          ),
          color: color ?? const Color.fromARGB(255, 225, 223, 223),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(10.0),
          child: child,
        ),
      ),
    );
  }
}
