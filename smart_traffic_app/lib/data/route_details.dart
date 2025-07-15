import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:traffic/model/route_model.dart';

class FirebaseRouteService {
  final DatabaseReference _comptageRef = FirebaseDatabase.instance.ref('comptage');
  final DatabaseReference _feuxRef = FirebaseDatabase.instance.ref('feux');

  Stream<List<RouteModel>> getRouteDataStream() {
    final controller = StreamController<List<RouteModel>>();

    Map<dynamic, dynamic>? comptageData;
    Map<dynamic, dynamic>? feuxData;

    // Fonction pour construire les RouteModel
    List<RouteModel> buildRouteModels() {
      final vehicules = comptageData?['vehicules'] as Map<dynamic, dynamic>? ?? {};
      final ambulances = comptageData?['ambulances'] as Map<dynamic, dynamic>? ?? {};
      final feux = feuxData ?? {
        'top': 'rouge',
        'bottom': 'rouge',
        'left': 'rouge',
        'right': 'rouge',
      };

      // Débogage : Afficher les données
      print('Données comptage: $comptageData');
      print('Feux extraits: $feux');

      int sum(String direction) {
        final v = int.tryParse(vehicules[direction]?.toString() ?? '0') ?? 0;
        final a = int.tryParse(ambulances[direction]?.toString() ?? '0') ?? 0;
        return v + a;
      }

      return [
        RouteModel(
          title: "Top",
          icon: 'icons/top.png',
          number: sum('top').toString(),
          carCount: vehicules['top']?.toString() ?? '0',
          ambulanceCount: ambulances['top']?.toString() ?? '0',
          feux: {
            'top': feux['top']?.toString() ?? 'rouge',
            'bottom': feux['bottom']?.toString() ?? 'rouge',
            'left': feux['left']?.toString() ?? 'rouge',
            'right': feux['right']?.toString() ?? 'rouge',
          },
          direction: 'top',
        ),
        RouteModel(
          title: "Bottom",
          icon: 'icons/bottom.png',
          number: sum('bottom').toString(),
          carCount: vehicules['bottom']?.toString() ?? '0',
          ambulanceCount: ambulances['bottom']?.toString() ?? '0',
          feux: {
            'top': feux['top']?.toString() ?? 'rouge',
            'bottom': feux['bottom']?.toString() ?? 'rouge',
            'left': feux['left']?.toString() ?? 'rouge',
            'right': feux['right']?.toString() ?? 'rouge',
          },
          direction: 'bottom',
        ),
        RouteModel(
          title: "Left",
          icon: 'icons/left.png',
          number: sum('left').toString(),
          carCount: vehicules['left']?.toString() ?? '0',
          ambulanceCount: ambulances['left']?.toString() ?? '0',
          feux: {
            'top': feux['top']?.toString() ?? 'rouge',
            'bottom': feux['bottom']?.toString() ?? 'rouge',
            'left': feux['left']?.toString() ?? 'rouge',
            'right': feux['right']?.toString() ?? 'rouge',
          },
          direction: 'left',
        ),
        RouteModel(
          title: "Right",
          icon: 'icons/right.png',
          number: sum('right').toString(),
          carCount: vehicules['right']?.toString() ?? '0',
          ambulanceCount: ambulances['right']?.toString() ?? '0',
          feux: {
            'top': feux['top']?.toString() ?? 'rouge',
            'bottom': feux['bottom']?.toString() ?? 'rouge',
            'left': feux['left']?.toString() ?? 'rouge',
            'right': feux['right']?.toString() ?? 'rouge',
          },
          direction: 'right',
        ),
      ];
    }

    // Écouter les changements sur comptage
    _comptageRef.onValue.listen((event) {
      comptageData = event.snapshot.value as Map<dynamic, dynamic>?;
      if (feuxData != null || comptageData != null) {
        controller.add(buildRouteModels());
      }
    }, onError: (error) {
      print('Erreur comptage: $error');
      controller.addError(error);
    });

    // Écouter les changements sur feux
    _feuxRef.onValue.listen((event) {
      feuxData = event.snapshot.value as Map<dynamic, dynamic>?;
      if (comptageData != null || feuxData != null) {
        controller.add(buildRouteModels());
      }
    }, onError: (error) {
      print('Erreur feux: $error');
      controller.addError(error);
    });

    // Fermer le controller quand le flux est annulé
    controller.onCancel = () {
      controller.close();
    };

    return controller.stream;
  }
}