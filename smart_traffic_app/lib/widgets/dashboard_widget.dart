import 'package:flutter/material.dart';
import 'package:traffic/util/responsive.dart';
import 'package:traffic/widgets/bar_graph_widget.dart';
import 'package:traffic/widgets/header_widgets.dart';
import 'package:traffic/widgets/activity_details_card.dart';
import 'package:traffic/widgets/line_chart_card.dart';
import 'package:traffic/widgets/side_menu_widget.dart';
import 'package:traffic/widgets/FooterMenu.dart';
import 'package:traffic/const/constant.dart';

class DashboardWidget extends StatefulWidget {
  const DashboardWidget({super.key});

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      // ✅ Drawer activé pour tous les modes (mobile, tablette, desktop)
      drawer: const SideMenuWidget(initialIndex: 0),
      onDrawerChanged: (isOpened) {
        setState(() {
          _isDrawerOpen = isOpened;
        });
      },
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: HeaderWidget(),
            ),
            // ✅ Contenu principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 18),
                    const ActivityDetailsCard(),
                    SizedBox(height: isMobile ? 6 : 1),
                    const LineChartCard(),
                    const SizedBox(height: 18),
                    if (Responsive.isTablet(context) || isMobile)
                      const BarGraphCard(),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
            // ✅ FooterMenu uniquement en mode mobile et drawer fermé
            if (isMobile && !_isDrawerOpen) const FooterMenu(),
          ],
        ),
      ),
    );
  }
}