import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../services/database_helper.dart';
import '../services/language_service.dart';

class HospitalScreen extends StatefulWidget {
  const HospitalScreen({super.key});

  @override
  State<HospitalScreen> createState() => _HospitalScreenState();
}

class _HospitalScreenState extends State<HospitalScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _hospitals = [];
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final position = await _getPosition();
      final facilities = await DatabaseHelper.instance.getHospitals();
      final enriched = facilities.map((h) {
        final lat = (h['latitude'] as num).toDouble();
        final lng = (h['longitude'] as num).toDouble();
        final km = _haversine(position.latitude, position.longitude, lat, lng);
        return {...h, '_distance_km': km};
      }).toList()
        ..sort((a, b) => (a['_distance_km'] as double).compareTo(b['_distance_km'] as double));
      setState(() { _userPosition = position; _hospitals = enriched; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<Position> _getPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) throw Exception('Location permission denied.');
    }
    if (perm == LocationPermission.deniedForever) throw Exception('Location permission permanently denied.');
    final locationSettings = kIsWeb
        ? WebSettings(accuracy: LocationAccuracy.high, distanceFilter: 100, maximumAge: const Duration(minutes: 5))
        : const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15));
    try {
      return await Geolocator.getCurrentPosition(locationSettings: locationSettings);
    } catch (e) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;
      rethrow;
    }
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double d) => d * pi / 180.0;

  Future<void> _call(String number) async {
    if (number.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final ls = LanguageService.instance;
    return Scaffold(
      appBar: AppBar(title: Text(ls.t('Nearby hospitals', 'Hospitali zilizo karibu'))),
      body: _buildBody(ls),
    );
  }

  Widget _buildBody(LanguageService ls) {
    if (_loading) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        Text(ls.t('Locating you…', 'Tunapata eneo lako…')),
      ]));
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _load, child: Text(ls.t('Try again', 'Jaribu tena'))),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                final fallback = Position(
                  latitude: -1.286389, longitude: 36.817223, timestamp: DateTime.now(),
                  accuracy: 100, altitude: 0, altitudeAccuracy: 0,
                  heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0,
                );
                final facilities = await DatabaseHelper.instance.getHospitals();
                final enriched = facilities.map((h) {
                  final km = _haversine(fallback.latitude, fallback.longitude,
                      (h['latitude'] as num).toDouble(), (h['longitude'] as num).toDouble());
                  return {...h, '_distance_km': km};
                }).toList()..sort((a, b) => (a['_distance_km'] as double).compareTo(b['_distance_km'] as double));
                setState(() { _userPosition = fallback; _hospitals = enriched; _loading = false; _error = null; });
              },
              child: Text(ls.t('Use default location (Nairobi) for testing', 'Tumia eneo la Nairobi kwa majaribio')),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.sageGreen.withOpacity(0.4), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.my_location, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _userPosition != null
                      ? '${ls.t('Location', 'Eneo')}: ${_userPosition!.latitude.toStringAsFixed(3)}, ${_userPosition!.longitude.toStringAsFixed(3)}'
                      : ls.t('Location unavailable', 'Eneo halipatikani'),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.softRedBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline, color: AppTheme.primaryRed, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ls.t(
                    'Facility details, hours and emergency capabilities may be outdated. Confirm by phone before travelling.',
                    'Taarifa za kituo, saa za kazi na uwezo wa dharura zinaweza kuwa za zamani. Thibitisha kwa simu kabla ya kusafiri.',
                  ),
                  style: const TextStyle(fontSize: 11, color: AppTheme.primaryRed),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Text(ls.t('Sorted by nearest', 'Zimepangwa kwa ukaribu'), style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          ..._hospitals.map((h) => _buildHospitalCard(h, ls)).toList(),
        ],
      ),
    );
  }

  Widget _buildHospitalCard(Map<String, dynamic> h, LanguageService ls) {
    final dist = h['_distance_km'] as double;
    final distLabel = dist < 1.0
        ? '${(dist * 1000).round()} ${ls.t('m away', 'm mbali')}'
        : '${dist.toStringAsFixed(1)} ${ls.t('km away', 'km mbali')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primaryRed.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.local_hospital, color: AppTheme.primaryRed, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ls.tr(h['name']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    if (h['county'] != null && (h['county'] as String).isNotEmpty)
                      Text(h['county'], style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              if (h['is_emergency_ready'] == 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.sageGreen, borderRadius: BorderRadius.circular(6)),
                  child: const Text('ER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(distLabel, style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (h['phone_number'] != null && (h['phone_number'] as String).isNotEmpty)
                      ? () => _call(h['phone_number'])
                      : null,
                  icon: const Icon(Icons.phone, size: 16),
                  label: Text(ls.t('Call', 'Piga')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
