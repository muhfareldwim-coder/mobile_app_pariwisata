import 'package:url_launcher/url_launcher.dart';

class OpenStreetMapService {
  static Uri directionsUri({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    return Uri.https('www.openstreetmap.org', '/directions', {
      'engine': 'fossgis_osrm_car',
      'route':
          '$fromLatitude,$fromLongitude;$toLatitude,$toLongitude',
    });
  }

  static Future<bool> openDirections({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    return launchUrl(
      directionsUri(
        fromLatitude: fromLatitude,
        fromLongitude: fromLongitude,
        toLatitude: toLatitude,
        toLongitude: toLongitude,
      ),
      mode: LaunchMode.externalApplication,
    );
  }
}
