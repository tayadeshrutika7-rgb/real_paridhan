import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapNavigationLauncher {
  /// Open turn-by-turn direct navigation with destination coordinates and optional origin (e.g. Shop -> Customer)
  static Future<bool> openGoogleMaps({
    required double latitude,
    required double longitude,
    double? originLatitude,
    double? originLongitude,
    String? destinationName,
    String? address,
    String? originName,
    BuildContext? context,
  }) async {
    // 1. Direct Turn-by-Turn Driving Navigation URL
    final queryParams = <String, String>{
      'api': '1',
      'destination': '$latitude,$longitude',
      'travelmode': 'driving',
      'dir_action': 'navigate',
    };
    if (originLatitude != null && originLongitude != null) {
      queryParams['origin'] = '$originLatitude,$originLongitude';
    }

    final googleMapsDirectionsUrl = Uri.https(
      'www.google.com',
      '/maps/dir/',
      queryParams,
    );

    // 2. Android Native Turn-by-Turn Navigation Intent
    final nativeNavUri = Uri.parse('google.navigation:q=$latitude,$longitude&mode=d');

    // 3. Android / Universal Geo URI
    final geoUri = Uri.parse(
      'geo:$latitude,$longitude?q=$latitude,$longitude(${Uri.encodeComponent(destinationName ?? address ?? "Destination")})',
    );

    // 4. Apple Maps Driving Directions URL
    final appleMapsUrl = Uri.parse(
      'https://maps.apple.com/?daddr=$latitude,$longitude&dirflg=d',
    );

    // 5. Universal Web Map URL
    final fallbackWebUrl = Uri.parse(
      'https://maps.google.com/?q=$latitude,$longitude',
    );

    final urisToTry = [
      nativeNavUri,
      googleMapsDirectionsUrl,
      geoUri,
      appleMapsUrl,
      fallbackWebUrl,
    ];

    for (final uri in urisToTry) {
      try {
        if (await canLaunchUrl(uri)) {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return true;
        }
      } catch (_) {
        // Continue to fallback
      }
    }

    // Final fallback to platform default browser
    try {
      if (await canLaunchUrl(fallbackWebUrl)) {
        return await launchUrl(fallbackWebUrl, mode: LaunchMode.platformDefault);
      }
    } catch (_) {}

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Directions route to ${destinationName ?? address ?? "destination"}: ($latitude, $longitude)'),
        ),
      );
    }

    return false;
  }

  /// Launch phone call dialer
  static Future<bool> makePhoneCall(String phoneNumber, {BuildContext? context}) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanNumber');

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('[MapNavigationLauncher] Error launching call: $e');
    }

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dialing $phoneNumber...')),
      );
    }
    return false;
  }
}

