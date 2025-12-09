import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se o serviço de localização está ativado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
          'Serviço de localização desativado. Ative o GPS e tente novamente.');
    }

    // Verifica permissão
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Pede permissão
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissão de localização negada.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissão negada permanentemente
      throw Exception(
          'Permissão de localização negada permanentemente. Habilite nas configurações do sistema.');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
