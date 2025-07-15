import 'package:flutter/material.dart';
import 'package:traffic/const/constant.dart';
import 'package:traffic/dashboardprincipale.dart';
import 'package:traffic/util/responsive.dart';
import 'package:traffic/widgets/side_menu_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const SideMenuWidget(initialIndex: 0), // Menu latéral utilisé pour mobile et desktop
      body: SafeArea(
        child: Column(
          children: [
            // Barre avec icône menu (mobile seulement)
            if (isMobile)
              Container(
                color: backgroundColor, // Fond noir
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.menu,
                          color: Color.fromARGB(255, 5, 5, 5),
                          size: 25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Contenu principal
            Expanded(
              child: Row(
                children: [
                  // Menu latéral (toujours visible sur tablette/desktop)
                  if (!isMobile)
                    const SizedBox(
                      width: 250, // Taille fixe du menu comme dans alerte.dart
                      child: SideMenuWidget(initialIndex: 0),
                    ),

                  // Dashboard
                  Expanded(
                    flex: isMobile ? 1 : 7,
                    child: Container(
                      color: backgroundColor, // Fond noir
                      child: const DashboardPrincipale(),
                    ),
                  ),
                ],
              ),
            ),
            
          ],
        ),
      ),
    );
  }
}
