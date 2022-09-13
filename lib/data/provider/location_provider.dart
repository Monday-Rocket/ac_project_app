import 'package:ac_project_app/data/model/location.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider {
  static Future<Location> getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    final currentPosition = await Geolocator.getCurrentPosition();
    return Location(currentPosition.latitude, currentPosition.longitude);
  }
}
