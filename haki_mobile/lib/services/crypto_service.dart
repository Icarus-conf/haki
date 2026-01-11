import 'dart:convert';

import 'package:asn1lib/asn1lib.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:cryptography/cryptography.dart' hide Hash;
import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart' as pc;

class CryptoService {
  static final _storage = const FlutterSecureStorage();
  static final _aesAlgorithm = AesGcm.with256bits();
  static final Map<String, String> _privKeyCache = {};

  Future<String?> _getPrivateKey(String username) async {
    if (_privKeyCache.containsKey(username)) return _privKeyCache[username];
    final key = await _storage.read(key: 'priv_key_$username');
    if (key != null) _privKeyCache[username] = key;
    return key;
  }

  /// Generates or retrieves RSA keypair.
  /// If a mnemonic is provided, it derives the key deterministically.
  Future<String> initKeys(String username, {String? mnemonic}) async {
    String? existingPrivKey = await _getPrivateKey(username);

    // If we have an existing key but no mnemonic was stored,
    // we might want to check if the provided mnemonic matches.
    // For now, if key exists, we stick with it.
    if (existingPrivKey != null && mnemonic == null) {
      var result = await RSA.convertPrivateKeyToPublicKey(existingPrivKey);
      return _stripPem(result);
    }

    String privKey;
    String pubKey;

    if (mnemonic != null) {
      debugPrint('Crypto: Generating deterministic RSA key from mnemonic...');
      final keys = await _generateDeterministicRSA(mnemonic);
      privKey = keys['private']!;
      pubKey = keys['public']!;
    } else {
      debugPrint('Crypto: Generating random RSA key...');
      var result = await RSA.generate(2048);
      privKey = result.privateKey;
      pubKey = result.publicKey;

      // Auto-generate a mnemonic for this new random key is NOT possible
      // because RSA isn't normally derived from seeds.
      // So we handle "New Account" by always generating a mnemonic FIRST now?
      // No, we'll keep it simple: if no mnemonic, it's a legacy random key.
    }

    // Store Private Key securely
    await _storage.write(key: 'priv_key_$username', value: privKey);
    return _stripPem(pubKey);
  }

  Future<String> generateMnemonic() async {
    return bip39.generateMnemonic();
  }

  Future<void> storeMnemonic(String username, String mnemonic) async {
    await _storage.write(key: 'mnemonic_$username', value: mnemonic);
  }

  Future<String?> getMnemonic(String username) async {
    return await _storage.read(key: 'mnemonic_$username');
  }

  Future<bool> hasViewedRecoveryPhrase(String username) async {
    final viewed = await _storage.read(key: 'recovery_viewed_$username');
    return viewed == 'true';
  }

  Future<void> markRecoveryPhraseViewed(String username) async {
    await _storage.write(key: 'recovery_viewed_$username', value: 'true');
  }

  Future<Map<String, String>> _generateDeterministicRSA(String mnemonic) async {
    // 1. Get seed from mnemonic (returns 64 bytes by default)
    final fullSeed = bip39.mnemonicToSeed(mnemonic);

    // 2. Fortuna requires exactly 32 bytes (256 bits)
    final seed = Uint8List.fromList(fullSeed.sublist(0, 32));

    // 3. Use PointyCastle to generate RSA deterministically
    final pc.SecureRandom secureRandom = _SeededRandom(seed);
    final keyGen = pc.RSAKeyGenerator()
      ..init(
        pc.ParametersWithRandom(
          pc.RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 12),
          secureRandom,
        ),
      );

    final pair = keyGen.generateKeyPair();
    final public = pair.publicKey as pc.RSAPublicKey;
    final private = pair.privateKey as pc.RSAPrivateKey;

    // Convert to PEM using ASN.1 encoding
    final privPem = _encodePrivateKeyToPem(private);
    final pubPem = _encodePublicKeyToPem(public);

    return {'private': privPem, 'public': pubPem};
  }

  String _encodePublicKeyToPem(pc.RSAPublicKey publicKey) {
    final algorithmSeq = ASN1Sequence();
    algorithmSeq.add(
      ASN1ObjectIdentifier(
        Uint8List.fromList([0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01]),
      ),
    ); // 1.2.840.113549.1.1.1 (rsaEncryption)
    algorithmSeq.add(ASN1Null());

    final rsaPublicKeySeq = ASN1Sequence();
    rsaPublicKeySeq.add(ASN1Integer(publicKey.modulus!));
    rsaPublicKeySeq.add(ASN1Integer(publicKey.exponent!));

    final publicKeyBitString = ASN1BitString(rsaPublicKeySeq.encodedBytes);

    final topLevelSeq = ASN1Sequence();
    topLevelSeq.add(algorithmSeq);
    topLevelSeq.add(publicKeyBitString);

    final bytes = topLevelSeq.encodedBytes;
    final base64 = base64Encode(bytes);

    return '-----BEGIN PUBLIC KEY-----\n${_formatPem(base64)}\n-----END PUBLIC KEY-----';
  }

  String _encodePrivateKeyToPem(pc.RSAPrivateKey privateKey) {
    final version = ASN1Integer(BigInt.zero); // version 0
    final modulus = ASN1Integer(privateKey.modulus!);
    final publicExponent = ASN1Integer(privateKey.publicExponent!);
    final privateExponent = ASN1Integer(privateKey.exponent!);
    final p = ASN1Integer(privateKey.p!);
    final q = ASN1Integer(privateKey.q!);
    final dP = ASN1Integer(privateKey.exponent! % (privateKey.p! - BigInt.one)); // d mod (p-1)
    final dQ = ASN1Integer(privateKey.exponent! % (privateKey.q! - BigInt.one)); // d mod (q-1)
    final qInv = ASN1Integer(privateKey.q!.modInverse(privateKey.p!)); // (inverse of q) mod p

    final sequence = ASN1Sequence();
    sequence.add(version);
    sequence.add(modulus);
    sequence.add(publicExponent);
    sequence.add(privateExponent);
    sequence.add(p);
    sequence.add(q);
    sequence.add(dP);
    sequence.add(dQ);
    sequence.add(qInv);

    final bytes = sequence.encodedBytes;
    final base64 = base64Encode(bytes);

    return '-----BEGIN RSA PRIVATE KEY-----\n${_formatPem(base64)}\n-----END RSA PRIVATE KEY-----';
  }

  String _formatPem(String base64String) {
    final buffer = StringBuffer();
    for (var i = 0; i < base64String.length; i += 64) {
      final end = (i + 64 < base64String.length) ? i + 64 : base64String.length;
      buffer.writeln(base64String.substring(i, end));
    }
    return buffer.toString().trimRight();
  }

  String _ensurePem(String key, {bool isPublic = true}) {
    if (key.contains('BEGIN ')) return key;

    // Clean all whitespace
    final cleanKey = key.replaceAll(RegExp(r'\s+'), '');

    // Standard PEM formatting requires line breaks every 64 characters
    final buffer = StringBuffer();
    final header = isPublic ? 'PUBLIC KEY' : 'PRIVATE KEY';
    buffer.writeln('-----BEGIN $header-----');
    for (var i = 0; i < cleanKey.length; i += 64) {
      final end = (i + 64 < cleanKey.length) ? i + 64 : cleanKey.length;
      buffer.writeln(cleanKey.substring(i, end));
    }
    buffer.write('-----END $header-----');
    return buffer.toString();
  }

  String _stripPem(String key) {
    if (key.isEmpty) return key;
    return key
        .replaceAll(RegExp(r'-----BEGIN (RSA )?(PUBLIC|PRIVATE) KEY-----'), '')
        .replaceAll(RegExp(r'-----END (RSA )?(PUBLIC|PRIVATE) KEY-----'), '')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .replaceAll(' ', '')
        .trim();
  }

  /// Hybrid Encryption: AES-256-GCM for data, RSA-OAEP for keys.
  /// Interoperable with Web Crypto API.
  Future<String> encrypt({
    required String text,
    required String recipientPubKey,
    required String senderPubKey,
  }) async {
    // 1. Generate random AES Session Key
    final secretKey = await _aesAlgorithm.newSecretKey();
    final secretKeyBytes = await secretKey.extractBytes();

    // 2. Encrypt text with AES-GCM
    final nonce = _aesAlgorithm.newNonce();
    final secretBox = await _aesAlgorithm.encrypt(
      utf8.encode(text),
      secretKey: secretKey,
      nonce: nonce,
    );

    // 3. Wrap the AES Key with RSA (OAEP SHA-256) for both parties
    final encryptedKeyR = await RSA.encryptOAEP(
      base64Encode(secretKeyBytes),
      "", // No label/identifier used in Web Crypto default
      Hash.SHA256,
      _ensurePem(recipientPubKey),
    );
    final encryptedKeyS = await RSA.encryptOAEP(
      base64Encode(secretKeyBytes),
      "", // No label/identifier used in Web Crypto default
      Hash.SHA256,
      _ensurePem(senderPubKey),
    );

    // 4. Return JSON blob
    return jsonEncode({
      "data": base64Encode([...secretBox.cipherText, ...secretBox.mac.bytes]),
      "iv": base64Encode(nonce),
      "keys": {"r": encryptedKeyR, "s": encryptedKeyS},
    });
  }

  /// Decrypts the hybrid payload using the local private key.
  Future<String> decrypt(String payloadStr, String username) async {
    Map<String, dynamic>? map;
    try {
      map = jsonDecode(payloadStr);
      if (map == null || map['data'] == null || map['keys'] == null) {
        return payloadStr; // Not our E2EE format (e.g. plain text global message)
      }
    } catch (e) {
      return payloadStr; // Not JSON at all (e.g. plain text)
    }

    try {
      final keys = map['keys'] as Map<String, dynamic>;
      final String? privKey = await _getPrivateKey(username);

      if (privKey == null) {
        debugPrint('Crypto: No Private Key found for $username');
        return "[No Private Key]";
      }

      final pemPrivKey = _ensurePem(privKey, isPublic: false);
      String? decryptedAesKeyBase64;
      List<String> errors = [];
      for (var encryptedKey in keys.values) {
        try {
          decryptedAesKeyBase64 = await RSA.decryptOAEP(encryptedKey, "", Hash.SHA256, pemPrivKey);
          if (decryptedAesKeyBase64.isNotEmpty) break;
        } catch (e) {
          errors.add(e.toString());
          continue;
        }
      }

      if (decryptedAesKeyBase64 == null) {
        debugPrint(
          'Crypto: Failed to decrypt AES key with local private key. Errors: ${errors.join(", ")}',
        );
        return "[Encrypted Message]";
      }

      final fullData = base64Decode(map['data']);
      if (fullData.length < 16) return "[Invalid Data]";

      // Split standard Web Crypto format: CipherText + 16-byte Tag
      final cipherText = fullData.sublist(0, fullData.length - 16);
      final macBytes = fullData.sublist(fullData.length - 16);

      final secretKey = SecretKey(base64Decode(decryptedAesKeyBase64));
      final secretBox = SecretBox(cipherText, nonce: base64Decode(map['iv']), mac: Mac(macBytes));

      final clearTextBytes = await _aesAlgorithm.decrypt(secretBox, secretKey: secretKey);

      return utf8.decode(clearTextBytes);
    } catch (e) {
      return "[Decryption Error]";
    }
  }

  /// Binary Hybrid Encryption for Media.
  Future<Map<String, dynamic>> encryptMedia({
    required Uint8List bytes,
    required String recipientPubKey,
    required String senderPubKey,
  }) async {
    final secretKey = await _aesAlgorithm.newSecretKey();
    final secretKeyBytes = await secretKey.extractBytes();

    final nonce = _aesAlgorithm.newNonce();
    final secretBox = await _aesAlgorithm.encrypt(bytes, secretKey: secretKey, nonce: nonce);

    final encryptedKeyR = await RSA.encryptOAEP(
      base64Encode(secretKeyBytes),
      "",
      Hash.SHA256,
      _ensurePem(recipientPubKey),
    );
    final encryptedKeyS = await RSA.encryptOAEP(
      base64Encode(secretKeyBytes),
      "",
      Hash.SHA256,
      _ensurePem(senderPubKey),
    );

    return {
      "data": Uint8List.fromList([...secretBox.cipherText, ...secretBox.mac.bytes]),
      "iv": base64Encode(nonce),
      "keys": {"r": encryptedKeyR, "s": encryptedKeyS},
    };
  }

  /// Binary Hybrid Decryption for Media.
  Future<Uint8List?> decryptMedia({
    required Uint8List encryptedBytes,
    required String ivBase64,
    required Map<String, dynamic> keys,
    required String username,
  }) async {
    try {
      final String? privKey = await _getPrivateKey(username);
      if (privKey == null) {
        debugPrint('Crypto: No Private Key found for $username');
        return null;
      }

      final pemPrivKey = _ensurePem(privKey, isPublic: false);
      String? decryptedAesKeyBase64;
      List<String> errors = [];
      int attempt = 1;
      for (var entry in keys.entries) {
        final keyRole = entry.key; // "r" or "s"
        final encryptedKey = entry.value;

        try {
          debugPrint(
            'Crypto: Decrypting media key ($keyRole) for user $username (Attempt $attempt)',
          );
          decryptedAesKeyBase64 = await RSA.decryptOAEP(encryptedKey, "", Hash.SHA256, pemPrivKey);
          if (decryptedAesKeyBase64.isNotEmpty) {
            debugPrint('Crypto: ✅ Successfully decrypted media key via role: $keyRole');
            break;
          }
        } catch (e) {
          errors.add('Role $keyRole: ${e.toString()}');
          attempt++;
          continue;
        }
      }

      if (decryptedAesKeyBase64 == null) {
        debugPrint(
          'Crypto: ❌ Failed to decrypt ANY media AES key for $username. Errors: ${errors.join(", ")}',
        );
        return null;
      }

      final cipherText = encryptedBytes.sublist(0, encryptedBytes.length - 16);
      final macBytes = encryptedBytes.sublist(encryptedBytes.length - 16);

      final secretKey = SecretKey(base64Decode(decryptedAesKeyBase64));
      final secretBox = SecretBox(cipherText, nonce: base64Decode(ivBase64), mac: Mac(macBytes));

      final clearTextBytes = await _aesAlgorithm.decrypt(secretBox, secretKey: secretKey);
      return Uint8List.fromList(clearTextBytes);
    } catch (e) {
      return null;
    }
  }
}

/// A seeded random number generator for PointyCastle
class _SeededRandom implements pc.SecureRandom {
  final pc.FortunaRandom _random = pc.FortunaRandom();
  bool _seeded = false;

  _SeededRandom(Uint8List seed) {
    final keyParam = pc.KeyParameter(seed);
    _random.seed(keyParam);
    _seeded = true;
  }

  @override
  String get algorithmName => 'Seeded Fortuna';

  @override
  BigInt nextBigInteger(int bitLength) => _random.nextBigInteger(bitLength);

  @override
  Uint8List nextBytes(int count) => _random.nextBytes(count);

  @override
  int nextUint16() => _random.nextUint16();

  @override
  int nextUint32() => _random.nextUint32();

  @override
  int nextUint8() => _random.nextUint8();

  @override
  void seed(pc.CipherParameters params) {
    if (!_seeded && params is pc.KeyParameter) {
      _random.seed(params);
      _seeded = true;
    }
  }
}
