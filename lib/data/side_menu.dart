import 'package:flutter/material.dart';
import 'package:traffic/model/menu_model.dart';

class SideMenuData {
  final menu = <MenuModel>[
        MenuModel(icon: Icons.location_on, title: 'Maps'),
    MenuModel(icon: Icons.home, title: 'Dashboard'),
    // Camera icon
    MenuModel(icon: Icons.camera_alt, title: 'Camera'), // Icône caméra
    // Alert icon
    MenuModel(icon: Icons.warning, title: 'Alertes'), 


    MenuModel(icon: Icons.logout, title: 'SignOut'),

  ];
}
