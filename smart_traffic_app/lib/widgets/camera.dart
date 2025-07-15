import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:traffic/widgets/side_menu_widget.dart';
import 'package:traffic/const/constant.dart';
import 'package:traffic/util/responsive.dart';
import 'package:traffic/widgets/FooterMenu.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late InAppWebViewController webViewController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    const Color backgroundColor = Color.fromARGB(255, 243, 241, 245);
    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? Drawer(
              width: 250,
              child: SideMenuWidget(
                initialIndex: 1,
                onItemSelected: (index) {
                  _scaffoldKey.currentState?.closeDrawer();
                },
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Barre avec icône menu (mobile seulement)
            if (isMobile)
              Container(
                color: backgroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.menu,
                          color: Color.fromARGB(255, 6, 6, 6),
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
                  // Menu latéral (affiché uniquement sur desktop/tablette)
                  if (!isMobile)
                    const SizedBox(
                      width: 250,
                      child: SideMenuWidget(initialIndex: 1),
                    ),

                  // Affichage de la caméra via WebView
                  Expanded(
                    child: InAppWebView(
                      initialUrlRequest: URLRequest(
                        url: WebUri("http://192.168.137.188:8000/"),
                      ),
                      onWebViewCreated: (controller) {
                        webViewController = controller;
                        // Inject CSS to enlarge the image
                        if (isMobile) {
                          controller.evaluateJavascript(source: """
                            var style = document.createElement('style');
                            style.innerHTML = 'img { width: 100%; height: auto; max-width: 100%; }';
                            document.head.appendChild(style);
                          """);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (isMobile) const FooterMenu(),
          ],
        ),
      ),
    );
  }
}