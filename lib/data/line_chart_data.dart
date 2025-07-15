import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class LineData {
  final Map<int, String> bottomTitle = {
    0: '00h', 
    20: '04h', 
    40: '08h',
    60: '12h', 
    80: '16h', 
    100: '20h', 
    120: '24h'
  };

  final Map<int, String> leftTitle = {
    0: '0', 
    20: '20', 
    40: '40',
    60: '60', 
    80: '80', 
    100: '100'
  };

  final List<FlSpot> spots = [
    FlSpot(0, 10),
    FlSpot(20, 35),
    FlSpot(40, 50),
    FlSpot(60, 75),
    FlSpot(80, 90),
    FlSpot(100, 60),
    FlSpot(120, 30)
  ];

  /// ⚡ Nouveau : Récupère les totaux d'ambulances + véhicules
  Stream<List<FlSpot>> getTotalStream() {
    final DatabaseReference vehiculesRef = FirebaseDatabase.instance.ref('comptage/vehicules/total');
    final DatabaseReference ambulancesRef = FirebaseDatabase.instance.ref('comptage/ambulances/total');

    // Combine les deux références
    return vehiculesRef.onValue.asyncMap((vehiculeEvent) async {
      final vehicules = (vehiculeEvent.snapshot.value as num?)?.toDouble() ?? 0;

      final ambulancesSnapshot = await ambulancesRef.get();
      final ambulances = (ambulancesSnapshot.value as num?)?.toDouble() ?? 0;

      final total = vehicules + ambulances;

      // On retourne un seul point pour l'exemple (x=0, y=total)
      return [FlSpot(0, total)];
    });
  }
}
