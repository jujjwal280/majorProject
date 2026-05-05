import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricVault {
  static final _auth = LocalAuthentication();

  static Future<bool> authenticate() async {
    try {
      final isAvailable = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (!isAvailable || !isDeviceSupported) return false;
      return await _auth.authenticate(
        localizedReason: 'Verify your identity to unlock the vault',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      assert(() {
        // ignore: avoid_print
        print("Vault auth error: $e");
        return true;
      }());
      return false;
    }
  }
}