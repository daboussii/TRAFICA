
import 'package:traffic/util/responsive.dart';
import 'package:flutter/material.dart';
import 'package:traffic/widgets/maps.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Menu button (for mobile)
        if (!Responsive.isDesktop(context))
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: InkWell(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(
                  Icons.menu,
                  color: Color.fromARGB(255, 9, 9, 9),
                  size: 25,
                ),
              ),
            ),
          ),

        // Search bar for desktop
        if (Responsive.isDesktop(context))
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor:  const Color.fromARGB(255, 225, 223, 223),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 5),
                hintText: 'Search',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color.fromARGB(255, 9, 9, 9),
                  size: 21,
                ),
              ),
            ),
          ),

        const SizedBox(width: 16),

        // Map icon in card-style for desktop
        if (Responsive.isDesktop(context))
          Container(
            decoration: BoxDecoration(
              
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 225, 223, 223),
                  spreadRadius: 1,
                  blurRadius: 6,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.map,
                color: Color.fromARGB(255, 9, 9, 9),
                size: 25,
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => GoogleMapScreen()),
                );
              },
            ),
          ),

        // Mobile only: Search & Map icons
        if (Responsive.isMobile(context))
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.search,
                  color: Color.fromARGB(255, 0, 0, 0),
                  size: 25,
                ),
                onPressed: () {
                  // Action pour la recherche mobile
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.map,
                  color: Color.fromARGB(255, 0, 0, 0),
                  size: 25,
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => GoogleMapScreen()),
                  );
                },
              ),
            ],
          ),
      ],
    );
  }
}