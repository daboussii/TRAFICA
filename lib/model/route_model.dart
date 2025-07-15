class RouteModel {
  final String title;
  final String icon;
  final String number;
  final String carCount;
  final String ambulanceCount;
  final String direction;
  final Map<String, String> feux;

  RouteModel({
    required this.title,
    required this.icon,
    required this.number,
    required this.carCount,
    required this.ambulanceCount,
    required this.direction,
    required this.feux,
  });
}