import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricVault {
  static final _auth = LocalAuthentication();

  static Future<bool> authenticate() async {
    try {
      // 1. Check if device supports biometrics
      final isAvailable = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      if (!isAvailable || !isDeviceSupported) return true; // Fallback for unsupported devices

      // 2. Trigger the Vault Door
      return await _auth.authenticate(
        localizedReason: 'Verify your identity to unlock the vault',
        options: const AuthenticationOptions(
          stickyAuth: true, // Keeps auth active if app goes to background briefly
          biometricOnly: true, // Forces fingerprint/FaceID over PIN
        ),
      );
    } on PlatformException catch (e) {
      print("Vault Error: $e");
      return false;
    }
  }
}