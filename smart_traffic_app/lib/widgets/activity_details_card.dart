import 'package:flutter/material.dart';
import 'package:traffic/const/constant.dart';
import 'package:traffic/data/route_details.dart';
import 'package:traffic/model/route_model.dart';
import 'package:traffic/util/responsive.dart';
import 'package:traffic/widgets/custom_card_widget.dart';

class ActivityDetailsCard extends StatefulWidget {
  const ActivityDetailsCard({super.key});

  @override
  State<ActivityDetailsCard> createState() => _ActivityDetailsCardState();
}

class _ActivityDetailsCardState extends State<ActivityDetailsCard> 
    with SingleTickerProviderStateMixin {
  final FirebaseRouteService _routeService = FirebaseRouteService();
  bool isIntersection2 = false;
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
    return StreamBuilder<List<RouteModel>>(
      stream: _routeService.getRouteDataStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.data == null || snapshot.data!.isEmpty) {
          return const Center(child: Text('Données non disponibles ou intersection 2'));
        }

        final routeData = snapshot.data!;

        return GridView.builder(
          itemCount: routeData.length,
          shrinkWrap: true,
          physics: const ScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: Responsive.isMobile(context) ? 2 : 4,
            crossAxisSpacing: Responsive.isMobile(context) ? 12 : 15,
            mainAxisSpacing: 12.0,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            String direction = routeData[index].direction;
            String feuColorString = routeData[index].feux[direction] ?? 'red';
            print('Direction: $direction, Couleur: $feuColorString, Feux: ${routeData[index].feux}');

            Color fireColor;
            switch (feuColorString.toLowerCase()) {
              case 'green':
              case 'vert':
                fireColor = Colors.green;
                break;
              case 'orange':
                fireColor = Colors.orange;
                break;
              case 'red':
              case 'rouge':
              default:
                fireColor = Colors.red;
                break;
            }

            return CustomCard(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Image.asset(
                        routeData[index].icon,
                        width: 50,
                        height: 50,
                      ),
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Icon(
                          Icons.circle,
                          color: fireColor,
                          size: 17,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 0),
                    child: Text(
                      routeData[index].number,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(255, 10, 10, 10),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    routeData[index].title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color.fromARGB(255, 52, 52, 52),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildAnimatedSmallCard(
                          routeData[index].ambulanceCount,
                          const Icon(
                            Icons.local_hospital,
                            size: 24,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildAnimatedSmallCard(
                          routeData[index].carCount,
                          const Icon(
                            Icons.directions_car,
                            size: 24,
                            color: Color.fromARGB(255, 8, 8, 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnimatedSmallCard(String count, Widget iconWidget) {
    return Card(
      color: selectionColor.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ScaleTransition(
              scale: _animation,
              child: iconWidget,
            ),
            const SizedBox(height: 4),
            Text(
              count,
              style: const TextStyle(
                fontSize: 12,
                color: Color.fromARGB(255, 3, 3, 3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}