import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:traffic/const/constant.dart';
import 'package:traffic/widgets/custom_card_widget.dart';

class LineChartCard extends StatefulWidget {
  const LineChartCard({super.key});

  @override
  State<LineChartCard> createState() => _LineChartCardState();
}

class _LineChartCardState extends State<LineChartCard> {
  final DatabaseReference _vehiculesRef = FirebaseDatabase.instance.ref('comptage/vehicules/total');
  final DatabaseReference _ambulancesRef = FirebaseDatabase.instance.ref('comptage/ambulances/total');
  final List<FlSpot> _spots = [];
  final Map<String, int> _timeData = {}; // Clé: "HH:mm", Valeur: Somme des totaux
  double _maxY = 20; // Valeur maximale initiale
  int? _touchedIndex;
  StreamSubscription<DatabaseEvent>? _vehiculesSubscription;
  StreamSubscription<DatabaseEvent>? _ambulancesSubscription;
  final DateFormat _timeFormat = DateFormat('HH:mm');
  final DateFormat _dayFormat = DateFormat('MMM dd');
  Timer? _cleanupTimer;

  @override
  void initState() {
    super.initState();
    _setupFirebaseListeners();
    _setupCleanupTimer();
  }

  @override
  void dispose() {
    _vehiculesSubscription?.cancel();
    _ambulancesSubscription?.cancel();
    _cleanupTimer?.cancel();
    super.dispose();
  }

  void _setupCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      final cutoffTime = DateTime.now().subtract(const Duration(days: 1));
      _timeData.removeWhere((key, value) {
        final dateTime = _timeFormat.parse(key, true);
        return dateTime.isBefore(cutoffTime);
      });
      _updateSpots();
    });
  }

  void _setupFirebaseListeners() {
    // Écoute des véhicules
    _vehiculesSubscription = _vehiculesRef.onValue.listen((event) {
      _processData(event, 'vehicules');
    }, onError: (error) {
      debugPrint('Firebase vehicles error: $error');
    });

    // Écoute des ambulances
    _ambulancesSubscription = _ambulancesRef.onValue.listen((event) {
      _processData(event, 'ambulances');
    }, onError: (error) {
      debugPrint('Firebase ambulances error: $error');
    });
  }

  void _processData(DatabaseEvent event, String type) {
    try {
      final value = event.snapshot.value as int? ?? 0;
      final timestamp = DateTime.now();
      final timeKey = _timeFormat.format(timestamp);

      if (!mounted) return;

      setState(() {
        // Ajouter ou mettre à jour la somme pour cette minute
        _timeData[timeKey] = (_timeData[timeKey] ?? 0) + value;

        // Mettre à jour la valeur maximale
        final maxValue = _timeData.values.reduce((a, b) => a > b ? a : b);
        if (maxValue > _maxY) {
          _maxY = maxValue.toDouble() * 1.1; // 10% de marge
        }

        // Garder seulement les 100 dernières minutes
        if (_timeData.length > 100) {
          final oldestKey = _timeData.keys.reduce((a, b) {
            final timeA = _timeFormat.parse(a, true);
            final timeB = _timeFormat.parse(b, true);
            return timeA.isBefore(timeB) ? a : b;
          });
          _timeData.remove(oldestKey);
        }

        _updateSpots();
        _touchedIndex = null;
      });
    } catch (e) {
      debugPrint('Error processing $type data: $e');
    }
  }

  void _updateSpots() {
    final sortedEntries = _timeData.entries.toList()
      ..sort((a, b) {
        final timeA = _timeFormat.parse(a.key, true);
        final timeB = _timeFormat.parse(b.key, true);
        return timeA.compareTo(timeB);
      });

    _spots.clear();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final time = _timeFormat.parse(entry.key);
      final dateTime = DateTime(today.year, today.month, today.day, time.hour, time.minute);
      final xValue = dateTime.millisecondsSinceEpoch.toDouble();
      _spots.add(FlSpot(xValue, entry.value.toDouble()));
    }
  }

  String _formatXValue(double value) {
    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());

    if (_timeData.isNotEmpty) {
      final firstTime = _timeFormat.parse(_timeData.keys.first, true);
      final lastTime = _timeFormat.parse(_timeData.keys.last, true);
      if (lastTime.difference(firstTime) > const Duration(days: 1)) {
        return _dayFormat.format(date);
      }
    }

    return _timeFormat.format(date);
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Real-time traffic density updates",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 16 / 6,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.lineBarSpots == null ||
                        !mounted) {
                      setState(() => _touchedIndex = null);
                      return;
                    }

                    setState(() {
                      final spotIndex = response.lineBarSpots?.first.spotIndex ?? -1;
                      _touchedIndex = spotIndex < _spots.length ? spotIndex : null;
                    });
                  },
                  getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((index) {
                      return TouchedSpotIndicatorData(
                        FlLine(color: Colors.grey[300]!, strokeWidth: 1),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: selectionColor,
                            );
                          },
                        ),
                      );
                    }).toList();
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                        return LineTooltipItem(
                          '${_timeFormat.format(date)}\n${spot.y.toInt()} (total)',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                    getTooltipColor: (LineBarSpot touchedSpot) => selectionColor,
                  ),
                ),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (_spots.isEmpty) return const SizedBox();
                        final firstX = _spots.first.x;
                        final lastX = _spots.last.x;
                        final range = lastX - firstX;
                        if ((value - firstX).abs() % (range / 4) > 0.1 * range &&
                            (value - lastX).abs() > 0.1 * range) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _formatXValue(value),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[400],
                            ),
                          ),
                        );
                      },
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final isTouched = _touchedIndex != null &&
                            _touchedIndex! < _spots.length &&
                            (_spots[_touchedIndex!].y - value).abs() < 0.1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: isTouched ? selectionColor : Colors.grey[400],
                              fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                      interval: _maxY > 20 ? _maxY / 5 : 5,
                      reservedSize: 28,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots,
                    color: selectionColor,
                    barWidth: 3,
                    isCurved: true,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          selectionColor.withOpacity(0.3),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: const FlDotData(show: false),
                    showingIndicators: _touchedIndex != null && _touchedIndex! < _spots.length
                        ? [_touchedIndex!]
                        : [],
                  ),
                ],
                minX: _spots.isNotEmpty ? _spots.first.x : DateTime.now().millisecondsSinceEpoch.toDouble(),
                maxX: _spots.isNotEmpty ? _spots.last.x : DateTime.now().millisecondsSinceEpoch.toDouble(),
                minY: 0,
                maxY: _maxY,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _touchedIndex != null && _touchedIndex! < _spots.length
                  ? 'Selected total: ${_spots[_touchedIndex!].y.toInt()} à ${_timeFormat.format(DateTime.fromMillisecondsSinceEpoch(_spots[_touchedIndex!].x.toInt()))}'
                  : 'Latest total: ${_spots.isNotEmpty ? _spots.last.y.toInt() : 0} à ${_spots.isNotEmpty ? _timeFormat.format(DateTime.fromMillisecondsSinceEpoch(_spots.last.x.toInt())) : "--:--"}',
              style: TextStyle(
                fontSize: 12,
                color: _touchedIndex != null ? selectionColor : Colors.grey[600],
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}