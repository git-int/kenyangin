import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

/// Hasil pemeriksaan izin + layanan lokasi perangkat.
enum LocationReadiness {
  ready,
  serviceDisabled,
  denied,
  deniedForever,
  unavailable,
}

/// Pembungkus tipis `geolocator` supaya provider tidak bergantung langsung
/// pada plugin dan pesan error bisa ditampilkan dalam bahasa Indonesia.
class LocationService {
  String? errorMessage;

  /// Pastikan GPS aktif dan izin lokasi sudah diberikan.
  Future<LocationReadiness> ensureReady() async {
    errorMessage = null;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        errorMessage =
            'Layanan lokasi (GPS) belum aktif. Nyalakan lokasi perangkat '
            'agar jarak toko bisa dihitung.';
        return LocationReadiness.serviceDisabled;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      switch (permission) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          return LocationReadiness.ready;
        case LocationPermission.deniedForever:
          errorMessage =
              'Izin lokasi diblokir. Aktifkan lewat Pengaturan aplikasi '
              'agar jarak toko tampil.';
          return LocationReadiness.deniedForever;
        case LocationPermission.denied:
        case LocationPermission.unableToDetermine:
          errorMessage =
              'Izin lokasi belum diberikan, jadi jarak toko belum bisa '
              'dihitung.';
          return LocationReadiness.denied;
      }
    } catch (error) {
      errorMessage = 'Lokasi perangkat tidak tersedia: ${_clean(error)}';
      return LocationReadiness.unavailable;
    }
  }

  /// Ambil satu posisi terbaru (akurasi tinggi) sebagai titik awal.
  Future<Position?> currentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      // Sebagian perangkat menolak getCurrentPosition; pakai posisi terakhir.
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (error) {
        errorMessage = 'Posisi perangkat tidak terbaca: ${_clean(error)}';
        return null;
      }
    }
  }

  /// Aliran posisi real-time. [distanceFilter] dalam meter supaya pembaruan
  /// tidak terlalu sering saat pengguna diam di tempat.
  Stream<Position> positionStream({int distanceFilter = 25}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    );
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Jarak permukaan bumi antara dua koordinat (rumus Haversine), kilometer.
  static double distanceInKm({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(toLatitude - fromLatitude);
    final dLon = _toRadians(toLongitude - fromLongitude);
    final lat1 = _toRadians(fromLatitude);
    final lat2 = _toRadians(toLatitude);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  /// Format jarak ramah pengguna: meter di bawah 1 km, kilometer di atasnya.
  static String formatDistance(double km) {
    if (km < 1) {
      final meter = (km * 1000).round();
      final rounded = meter < 50 ? 50 : (meter / 10).round() * 10;
      return '± $rounded m';
    }
    if (km < 10) {
      return '± ${km.toStringAsFixed(1).replaceAll('.', ',')} km';
    }
    return '± ${km.round()} km';
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;

  static String _clean(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
