import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where keys and the sign-in token live: the Keychain on Apple devices, the platform vault elsewhere.
const secureStorage = FlutterSecureStorage(mOptions: _MacKeychain());

/// macOS: the login keychain. The data-protection keychain needs a signed keychain-sharing
/// entitlement (error -34018 without it).
class _MacKeychain extends MacOsOptions {
  const _MacKeychain() : super(usesDataProtectionKeychain: false);

  // flutter_secure_storage 10.0.0 sends `usesDataProtectionKeychain`, but its macOS side reads
  // `useDataProtectionKeyChain`; send both so the setting actually arrives.
  @override
  Map<String, String> toMap() => {...super.toMap(), 'useDataProtectionKeyChain': 'false'};
}
