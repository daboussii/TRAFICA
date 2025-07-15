import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:traffic/screen/main_screen.dart';
import 'package:traffic/widgets/side_menu_widget.dart';
import 'package:traffic/util/responsive.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;

class GoogleMapScreen extends StatefulWidget {
  @override
  _GoogleMapScreenState createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  late gmap.GoogleMapController mapController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final gmap.LatLng _center = gmap.LatLng(34.7406, 10.7603); // Tunis
  late latlong.LatLng _flutterMapCenter;

  Map<String, dynamic> trafficData = {};
  final Color backgroundColor = const Color.fromARGB(255, 243, 241, 245);
  DatabaseReference dbRef = FirebaseDatabase.instance.ref('comptage/vehicules');
  String? _selectedWebIntersection;
  gmap.MarkerId? _selectedMarkerId;

  @override
  void initState() {
    super.initState();
    _flutterMapCenter = latlong.LatLng(_center.latitude, _center.longitude);
    dbRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          trafficData = Map<String, dynamic>.from(data);
        });
      }
    });
  }

  void _onMapCreated(gmap.GoogleMapController controller) {
    mapController = controller;
  }

  void _onMarkerTapped(gmap.MarkerId markerId) {
    setState(() {
      _selectedMarkerId = markerId;
    });
  }

  void _onWebMarkerTapped(String id) {
    setState(() {
      _selectedWebIntersection = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isWeb = kIsWeb;

    int total = 0;
    bool isIntersection1 = (_selectedMarkerId == gmap.MarkerId("intersection1")) ||
        (_selectedWebIntersection == "intersection1");

    if (trafficData.isNotEmpty && isIntersection1) {
      total = (trafficData['top'] ?? 0) +
          (trafficData['bottom'] ?? 0) +
          (trafficData['left'] ?? 0) +
          (trafficData['right'] ?? 0);
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: isMobile
          ? Drawer(
              width: 250,
              child: SideMenuWidget(
                initialIndex: 2,
                onItemSelected: (index) {
                  _scaffoldKey.currentState?.closeDrawer();
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
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: const Icon(
                        Icons.menu,
                        color: Color.fromARGB(179, 5, 5, 5),
                        size: 28,
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
                      child: SideMenuWidget(initialIndex: 2),
                    ),
                  Expanded(
                    child: Stack(
                      children: [
                        if (isWeb)
                          fmap.FlutterMap(
                            options: fmap.MapOptions(
                              center: _flutterMapCenter,
                              zoom: 12.0,
                              onTap: (_, __) {
                                setState(() {
                                  _selectedWebIntersection = null;
                                });
                              },
                            ),
                            children: [
                              fmap.TileLayer(
                                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                subdomains: ['a', 'b', 'c'],
                              ),
                              fmap.MarkerLayer(
                                markers: [
                                  fmap.Marker(
                                    point: _flutterMapCenter,
                                    width: 80.0,
                                    height: 80.0,
                                    builder: (context) => GestureDetector(
                                      onTap: () => _onWebMarkerTapped("intersection1"),
                                      child: const Icon(
                                        Icons.location_on,
                                        size: 40,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                  fmap.Marker(
                                    point: latlong.LatLng(34.7406, 10.7690),
                                    width: 80.0,
                                    height: 80.0,
                                    builder: (context) => GestureDetector(
                                      onTap: () => _onWebMarkerTapped("intersection2"),
                                      child: const Icon(
                                        Icons.location_on,
                                        size: 40,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          gmap.GoogleMap(
                            onMapCreated: _onMapCreated,
                            initialCameraPosition: gmap.CameraPosition(
                              target: _center,
                              zoom: 12.0,
                            ),
                            markers: {
                              gmap.Marker(
                                markerId: gmap.MarkerId("intersection1"),
                                position: _center,
                                infoWindow: const gmap.InfoWindow(title: "Sfax Isims Intersection"),
                                onTap: () => _onMarkerTapped(gmap.MarkerId("intersection1")),
                                icon: gmap.BitmapDescriptor.defaultMarkerWithHue(
                                  gmap.BitmapDescriptor.hueRed,
                                ),
                              ),
                              gmap.Marker(
                                markerId: gmap.MarkerId("intersection2"),
                                position: const gmap.LatLng(36.8000, 10.1830),
                                infoWindow: const gmap.InfoWindow(title: "Sfax City Center Intersection"),
                                onTap: () => _onMarkerTapped(gmap.MarkerId("intersection2")),
                                icon: gmap.BitmapDescriptor.defaultMarkerWithHue(
                                  gmap.BitmapDescriptor.hueBlue,
                                ),
                              ),
                            },
                          ),
                        if (_selectedMarkerId != null || _selectedWebIntersection != null)
                          Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20,
                            child: Card(
                              color: Colors.white.withOpacity(0.95),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isIntersection1
                                          ? "Sfax Isims Intersection"
                                          : "Sfax City Center Intersection",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (isIntersection1) ...[
                                      Text(
                                        "Total Vehicles: $total",
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const MainScreen(),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.dashboard),
                                          label: const Text("Details"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color.fromARGB(255, 255, 212, 51),
                                            foregroundColor: const Color.fromARGB(255, 6, 6, 6),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        "Traffic data not available for this intersection.",
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
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

  @override
  void dispose() {
    super.dispose();
  }
}