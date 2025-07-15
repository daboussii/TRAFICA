import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:traffic/model/alerte_model.dart';
import 'package:traffic/util/responsive.dart';
import 'package:traffic/widgets/side_menu_widget.dart';
import 'package:traffic/const/constant.dart';
import 'package:traffic/widgets/FooterMenu.dart';

class AlertePage extends StatefulWidget {
  const AlertePage({Key? key}) : super(key: key);

  @override
  State<AlertePage> createState() => _AlertePageState();
}

class _AlertePageState extends State<AlertePage> {
  Map<String, dynamic>? accidentData;
  Map<String, dynamic>? workData;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() {
    final database = FirebaseDatabase.instance.ref();

    database.child("comptage/accidents").onValue.listen((event) {
      if (!mounted) return;
      try {
        final value = event.snapshot.value;
        print("Accidents raw data: $value (type: ${value.runtimeType})");
        if (value == null) {
          print("Accidents data is null");
          setState(() {
            accidentData = null;
          });
        } else if (value is Map) {
          setState(() {
            accidentData = Map<String, dynamic>.from(value);
            print("Accident data set: $accidentData");
          });
        } else {
          print("Accidents data is not a Map: $value");
          setState(() {
            accidentData = null;
          });
        }
      } catch (e, stackTrace) {
        print("Error fetching accident data: $e\nStack trace: $stackTrace");
        setState(() {
          accidentData = null;
        });
      }
    }, onError: (error, stackTrace) {
      print("Accidents stream error: $error\nStack trace: $stackTrace");
      if (mounted) {
        setState(() {
          accidentData = null;
        });
      }
    });

    database.child("comptage/works").onValue.listen((event) {
      if (!mounted) return;
      try {
        final value = event.snapshot.value;
        print("Works raw data: $value (type: ${value.runtimeType})");
        if (value == null) {
          print("Works data is null");
          setState(() {
            workData = null;
          });
        } else if (value is Map) {
          setState(() {
            workData = Map<String, dynamic>.from(value);
            print("Work data set: $workData");
          });
        } else {
          print("Works data is not a Map: $value");
          setState(() {
            workData = null;
          });
        }
      } catch (e, stackTrace) {
        print("Error fetching work data: $e\nStack trace: $stackTrace");
        setState(() {
          workData = null;
        });
      }
    }, onError: (error, stackTrace) {
      print("Works stream error: $error\nStack trace: $stackTrace");
      if (mounted) {
        setState(() {
          workData = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final scaffoldKey = GlobalKey<ScaffoldState>();

    final List<AlerteModel> alerts = [];

    // Accident alert
    if (accidentData != null && accidentData?['total'] == true) {
      print("Accident alert triggered: $accidentData");
      alerts.add(AlerteModel(
        title: "Accident Alert",
        description: "Reported accident on your route.",
        icon: "report_problem",
        directions: [],
      ));
    }

    // Road works alert
    if (workData != null && workData?['total'] == true) {
      print("Road works alert triggered: $workData");
      alerts.add(AlerteModel(
        title: "Road Works",
        description: "Ongoing construction work.",
        icon: "engineering",
        directions: [],
      ));
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: isMobile
          ? Drawer(
              width: 250,
              child: SideMenuWidget(
                initialIndex: 3,
                onItemSelected: (_) {
                  scaffoldKey.currentState?.closeDrawer();
                },
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (isMobile)
              Container(
                color: backgroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => scaffoldKey.currentState?.openDrawer(),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.menu,
                          color: Color.fromARGB(255, 7, 7, 7),
                          size: 25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Row(
                children: [
                  if (!isMobile)
                    const SizedBox(
                      width: 250,
                      child: SideMenuWidget(initialIndex: 3),
                    ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 80),
                          children: [
                            if (alerts.isEmpty)
                              Center(
                                child: Text(
                                  "No alert at the moment",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              )
                            else
                              ...alerts.map((alert) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6, horizontal: 20),
                                    child: _AlertCard(alert: alert),
                                  ))
                          ],
                        ),
                      ),
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

  @override
  void dispose() {
    super.dispose();
  }
}

class _AlertCard extends StatelessWidget {
  final AlerteModel alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color iconColor;

    switch (alert.title) {
      case "Accident Alert":
        backgroundColor = const Color.fromARGB(255, 251, 251, 251).withOpacity(0.8);
        iconColor = const Color(0xFFD32F2F);
        break;
      case "Road Works":
        backgroundColor = const Color.fromARGB(255, 252, 252, 251).withOpacity(0.8);
        iconColor = selectionColor;
        break;
      default:
        backgroundColor = Colors.grey[200]!.withOpacity(0.8);
        iconColor = Colors.grey[700]!;
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 400,
        minWidth: 300,
      ),
      child: Container(
        height: 140,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
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
                icon: _getIconFromName(alert.icon),
                color: iconColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      alert.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 9, 9, 9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alert.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 59, 59, 59),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showAlertDialog(context, alert),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[500],
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showAlertDialog(BuildContext context, AlerteModel alert) {
  Color iconColor;
  switch (alert.title) {
    case "Accident Alert":
      iconColor = const Color(0xFFD32F2F);
      break;
    case "Road Works":
      iconColor = selectionColor;
      break;
    default:
      iconColor = Colors.grey[700]!;
  }

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: const Color.fromARGB(255, 255, 254, 252),
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedIconContainer(
                    icon: _getIconFromName(alert.icon),
                    color: iconColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    alert.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 5, 5, 5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alert.description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(179, 26, 25, 25),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 8, 8, 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

IconData _getIconFromName(String name) {
  switch (name) {
    case "report_problem":
      return Icons.report_problem;
    case "engineering":
      return Icons.engineering;
    default:
      return Icons.help;
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
          size: 30,
        ),
      ),
    );
  }
}