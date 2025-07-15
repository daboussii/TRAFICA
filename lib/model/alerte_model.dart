class AlerteModel {
  final String title;
  final String description;
  final String icon;
  final List<String> directions; // Nom de l'icône pour l'alerte

  AlerteModel({
    required this.title,
    required this.description,
    required this.icon,
     required this.directions,
  });
}
