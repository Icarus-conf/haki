import 'dart:convert';
import 'dart:isolate';

import 'package:asn1lib/asn1lib.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:cryptography/cryptography.dart' hide Hash;
import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart' as pc;
import 'secure_storage.dart';

class CryptoService {
  static final _storage = secureStorage;
  static final _aesAlgorithm = AesGcm.with256bits();

  /// What [decrypt] returns when this phone's key can't open a message
  /// (e.g. it was sent to a key the user has since replaced).
  static const undecryptable = {'[No Private Key]', '[Encrypted Message]', '[Invalid Data]', '[Decryption Error]'};

  /// Safety number: SHA-512 over the (order-independent) public keys, shown as
  /// 12 groups of 5 digits. Both people see the same number when no key was swapped.
  /// With one key it is that key's own fingerprint.
  static Future<String> safetyNumber(List<String> publicKeys) async {
    final normalized = publicKeys.map((k) => k.replaceAll(RegExp(r'\s'), '')).toList()..sort();
    final bytes = (await Sha512().hash(utf8.encode(normalized.join('|')))).bytes; // 64 bytes
    final groups = <String>[];
    for (var i = 0; i < 12; i++) {
      // 5 bytes -> number -> 5 digits (same idea as Signal's safety numbers)
      var n = 0;
      for (var j = 0; j < 5; j++) {
        n = (n * 256 + bytes[i * 5 + j]) % 100000;
      }
      groups.add(n.toString().padLeft(5, '0'));
    }
    return groups.join(' ');
  }
  static final Map<String, String> _privKeyCache = {};

  /// RSA modulus of a public key in either format the server may hold: X.509
  /// SubjectPublicKeyInfo (word-derived keys) or PKCS#1 (re-published by fast_rsa).
  static BigInt? publicKeyModulus(String key) {
    try {
      final body = key.replaceAll(RegExp(r'-----[A-Z ]+-----|\s'), '');
      var seq = ASN1Parser(base64Decode(body)).nextObject() as ASN1Sequence;
      if (seq.elements.first is ASN1Sequence) {
        // X.509: SEQUENCE { algorithm, BIT STRING { RSAPublicKey } }
        final bits = seq.elements[1] as ASN1BitString;
        seq = ASN1Parser(Uint8List.fromList(bits.stringValue)).nextObject() as ASN1Sequence;
      }
      return (seq.elements.first as ASN1Integer).valueAsBigInteger;
    } catch (_) {
      return null;
    }
  }

  /// Short id of a public key that ignores its encoding (two encodings of one key match).
  static Future<String?> keyFingerprint(String key) async {
    final m = publicKeyModulus(key);
    if (m == null) return null;
    final h = await Sha256().hash(utf8.encode(m.toRadixString(16)));
    return h.bytes.take(12).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Same key pair, regardless of encoding.
  static bool sameKey(String a, String b) {
    final ma = publicKeyModulus(a);
    return ma != null && ma == publicKeyModulus(b);
  }

  // ===== Linking a device =====
  // The new device makes a one-time X25519 key and shows it in a QR. The phone derives a shared
  // AES key with its own one-time key (X25519 + HKDF) and seals the account key to it. The server
  // relays the sealed blob but can't open it. Both screens show a 6-digit check of the new
  // device's key, so a server swapping keys would show different digits.

  static Future<(SimpleKeyPair, String)> linkKeyPair() async {
    final kp = await X25519().newKeyPair();
    return (kp, base64Encode((await kp.extractPublicKey()).bytes));
  }

  static Future<SecretKey> _linkKey(SimpleKeyPair mine, String theirPub) async {
    final shared = await X25519().sharedSecretKey(
      keyPair: mine,
      remotePublicKey: SimplePublicKey(base64Decode(theirPub), type: KeyPairType.x25519),
    );
    return Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(secretKey: shared, nonce: utf8.encode('haki-link-v1'));
  }

  /// Phone side: returns (sealed, my one-time public key).
  static Future<(String, String)> sealForLink(String plaintext, String theirPub) async {
    final (mine, minePub) = await linkKeyPair();
    final box = await _aesAlgorithm.encrypt(utf8.encode(plaintext), secretKey: await _linkKey(mine, theirPub));
    return (base64Encode(box.concatenation()), minePub);
  }

  /// New device side.
  static Future<String> openLink(String sealed, SimpleKeyPair mine, String theirPub) async {
    final box = SecretBox.fromConcatenation(base64Decode(sealed), nonceLength: 12, macLength: 16);
    return utf8.decode(await _aesAlgorithm.decrypt(box, secretKey: await _linkKey(mine, theirPub)));
  }

  /// "123 456": what both screens show for the new device's one-time key.
  static Future<String> linkCheck(String pub) async {
    final h = (await Sha256().hash(base64Decode(pub))).bytes;
    final n = ((h[0] << 16) | (h[1] << 8) | h[2]) % 1000000;
    final d = n.toString().padLeft(6, '0');
    return '${d.substring(0, 3)} ${d.substring(3)}';
  }

  Future<String?> exportPrivateKey(String username) => _getPrivateKey(username);

  Future<void> importPrivateKey(String username, String privateKey) async {
    await _storage.write(key: 'priv_key_$username', value: privateKey);
    _privKeyCache[username] = privateKey;
  }

  /// Whether this phone already holds a private key for [username].
  Future<bool> hasLocalKey(String username) async => await _getPrivateKey(username) != null;

  /// Public key the 12 words would produce, without storing anything.
  Future<String> publicKeyFromWords(String mnemonic) async =>
      _stripPem((await _generateDeterministicRSA(mnemonic))['public']!);

  Future<String?> _getPrivateKey(String username) async {
    if (_privKeyCache.containsKey(username)) return _privKeyCache[username];
    final key = await _storage.read(key: 'priv_key_$username');
    if (key != null) _privKeyCache[username] = key;
    return key;
  }

  /// Generates or retrieves the RSA key pair; with [mnemonic] it is derived from the words.
  /// Always returns the public key in one canonical encoding (fast_rsa's), so every phone of
  /// an account publishes the identical string and friends don't see spurious key changes.
  Future<String> initKeys(String username, {String? mnemonic}) async {
    var privKey = await _getPrivateKey(username);
    if (privKey == null || mnemonic != null) {
      if (mnemonic != null) {
        debugPrint('Crypto: Deriving RSA key from recovery words...');
        privKey = (await _generateDeterministicRSA(mnemonic))['private']!;
      } else {
        // Legacy accounts without words; new accounts always come with words
        privKey = (await RSA.generate(2048)).privateKey;
      }
      // Store securely and refresh the cache, or decrypt keeps using the old key
      await _storage.write(key: 'priv_key_$username', value: privKey);
      _privKeyCache[username] = privKey;
    }
    return _stripPem(await RSA.convertPrivateKeyToPublicKey(privKey));
  }

  /// True when [mnemonic] really re-creates this device's private key. Accounts made
  /// before the registration fix stored words that never matched their key.
  Future<bool> mnemonicMatchesKey(String username, String mnemonic) async {
    final current = await _getPrivateKey(username);
    if (current == null) return false;
    final derived = await _generateDeterministicRSA(mnemonic);
    return derived['private'] == current;
  }

  /// New words + a new key pair derived from them. Returns (mnemonic, public key).
  /// Messages encrypted to the previous key can no longer be decrypted after this.
  Future<(String, String)> createNewRecoveryPhrase(String username) async {
    final mnemonic = await generateMnemonic();
    final pubKey = await initKeys(username, mnemonic: mnemonic);
    await storeMnemonic(username, mnemonic);
    return (mnemonic, pubKey);
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

  /// Deterministic 2048-bit keygen is seconds of pure-Dart math (much longer in debug
  /// builds). On the UI isolate it froze the screen, spinner included, so run it on its own.
  Future<Map<String, String>> _generateDeterministicRSA(String mnemonic) =>
      Isolate.run(() => _deriveKeyPair(mnemonic));

  static Map<String, String> _deriveKeyPair(String mnemonic) {
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
    final pubPem = _encodePublicKeyToPemStatic(public);

    return {'private': privPem, 'public': pubPem};
  }

  /// X.509 SubjectPublicKeyInfo PEM. The OID must be given as components: passing its
  /// already-encoded bytes double-encoded it and produced keys nobody could encrypt to.
  @visibleForTesting
  static String encodePublicKeyPem(pc.RSAPublicKey publicKey) => _encodePublicKeyToPemStatic(publicKey);


  static String _encodePublicKeyToPemStatic(pc.RSAPublicKey publicKey) {
    final algorithmSeq = ASN1Sequence();
    algorithmSeq.add(ASN1ObjectIdentifier.fromComponentString('1.2.840.113549.1.1.1')); // rsaEncryption
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

  static String _encodePrivateKeyToPem(pc.RSAPrivateKey privateKey) {
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

  static String _formatPem(String base64String) {
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
  }) => encryptFor(text, {'r': recipientPubKey, 's': senderPubKey});

  /// Same format with one wrapped key per reader (groups use member ids as names).
  Future<String> encryptFor(String text, Map<String, String> publicKeys) async {
    final secretKey = await _aesAlgorithm.newSecretKey();
    final nonce = _aesAlgorithm.newNonce();
    final secretBox = await _aesAlgorithm.encrypt(utf8.encode(text), secretKey: secretKey, nonce: nonce);
    return jsonEncode({
      "data": base64Encode([...secretBox.cipherText, ...secretBox.mac.bytes]),
      "iv": base64Encode(nonce),
      "keys": await _wrapKey(await secretKey.extractBytes(), publicKeys),
    });
  }

  /// RSA-OAEP (SHA-256) wraps the AES key once per reader.
  Future<Map<String, String>> _wrapKey(List<int> secretKeyBytes, Map<String, String> publicKeys) async {
    final b64 = base64Encode(secretKeyBytes);
    final entries = await Future.wait(publicKeys.entries.map(
      (e) async => MapEntry(e.key, await RSA.encryptOAEP(b64, "", Hash.SHA256, _ensurePem(e.value))),
    ));
    return Map.fromEntries(entries);
  }

  /// Decrypts the hybrid payload using the local private key.
  /// [preferKey] names the wrapped key that is probably ours (a member id in groups), so a
  /// big group doesn't cost one failed RSA attempt per member.
  Future<String> decrypt(String payloadStr, String username, {String? preferKey}) async {
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
      final ordered = [?keys[preferKey], ...keys.entries.where((e) => e.key != preferKey).map((e) => e.value)];
      for (var encryptedKey in ordered) {
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
  }) => encryptMediaFor(bytes, {'r': recipientPubKey, 's': senderPubKey});

  Future<Map<String, dynamic>> encryptMediaFor(Uint8List bytes, Map<String, String> publicKeys) async {
    final secretKey = await _aesAlgorithm.newSecretKey();
    final nonce = _aesAlgorithm.newNonce();
    final secretBox = await _aesAlgorithm.encrypt(bytes, secretKey: secretKey, nonce: nonce);
    return {
      "data": Uint8List.fromList([...secretBox.cipherText, ...secretBox.mac.bytes]),
      "iv": base64Encode(nonce),
      "keys": await _wrapKey(await secretKey.extractBytes(), publicKeys),
    };
  }

  // ===== Feed: one AES key per post, wrapped once per reader; text, media and comments reuse it =====

  /// A fresh post key and its wrapped copies, keyed like [publicKeys] (user ids).
  Future<(List<int>, Map<String, String>)> newPostKey(
    Map<String, String> publicKeys,
  ) async {
    final key = await (await _aesAlgorithm.newSecretKey()).extractBytes();
    return (key, await _wrapKey(key, publicKeys));
  }

  /// My copy of a post key, or null if it isn't for this account.
  Future<List<int>?> unwrapPostKey(String wrapped, String username) async {
    final priv = await _getPrivateKey(username);
    if (priv == null) return null;
    try {
      return base64Decode(
        await RSA.decryptOAEP(
          wrapped,
          "",
          Hash.SHA256,
          _ensurePem(priv, isPublic: false),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// AES-GCM with [key]; returns the sealed bytes (cipher + tag) and the base64 nonce.
  Future<(Uint8List, String)> sealBytes(List<int> key, List<int> clear) async {
    final nonce = _aesAlgorithm.newNonce();
    final box = await _aesAlgorithm.encrypt(
      clear,
      secretKey: SecretKey(key),
      nonce: nonce,
    );
    return (
      Uint8List.fromList([...box.cipherText, ...box.mac.bytes]),
      base64Encode(nonce),
    );
  }

  Future<Uint8List?> openBytes(
    List<int> key,
    Uint8List sealed,
    String iv,
  ) async {
    if (sealed.length < 16) return null;
    try {
      final box = SecretBox(
        sealed.sublist(0, sealed.length - 16),
        nonce: base64Decode(iv),
        mac: Mac(sealed.sublist(sealed.length - 16)),
      );
      return Uint8List.fromList(
        await _aesAlgorithm.decrypt(box, secretKey: SecretKey(key)),
      );
    } catch (_) {
      return null;
    }
  }

  /// Text as the server stores it: `{"data", "iv"}`.
  Future<String> sealText(List<int> key, String text) async {
    final (data, iv) = await sealBytes(key, utf8.encode(text));
    return jsonEncode({'data': base64Encode(data), 'iv': iv});
  }

  Future<String?> openText(List<int> key, String sealed) async {
    try {
      final m = jsonDecode(sealed) as Map<String, dynamic>;
      final clear = await openBytes(key, base64Decode(m['data']), m['iv']);
      return clear == null ? null : utf8.decode(clear);
    } catch (_) {
      return null;
    }
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
