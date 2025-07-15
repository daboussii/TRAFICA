import 'package:flutter/material.dart';
import 'package:traffic/util/responsive.dart';
import 'package:traffic/widgets/side_menu_widget.dart';
import 'package:traffic/widgets/dashboard_widget.dart';
import 'package:traffic/widgets/bar_graph_widget.dart';
import 'package:traffic/widgets/FooterMenu.dart'; // Import FooterMenu

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      drawer: !isDesktop
          ? const SizedBox(
              width: 250,
              child: SideMenuWidget(),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  if (isDesktop)
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        child: SideMenuWidget(),
                      ),
                    ),
                  Expanded(
                    flex: 7,
                    child: SizedBox(
                      child: DashboardWidget(),
                    ),
                  ),
                  if (isDesktop)
                    Expanded(
                      flex: 3,
                      child: BarGraphCard(),
                    ),
                ],
              ),
            ),
            // FooterMenu only for mobile
      
          ],
        ),
      ),
    );
  }
}