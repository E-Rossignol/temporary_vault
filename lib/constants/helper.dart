import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class Helper {
  // ----- Helpers -----
  static Uint8List _deriveKey(
    String password,
    Uint8List salt, {
    int iterations = 10000,
    int keyLength = 32,
  }) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    final params = Pbkdf2Parameters(salt, iterations, keyLength);
    pbkdf2.init(params);
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  static Uint8List _randomBytes(int length) {
    final rnd = _secureRandom();
    return rnd.nextBytes(length);
  }

  static SecureRandom _secureRandom() {
    final secure = FortunaRandom();
    final seed = Uint8List(32);
    final rand = Random.secure();
    for (int i = 0; i < seed.length; i++) {
      seed[i] = rand.nextInt(256);
    }
    secure.seed(KeyParameter(seed));
    return secure;
  }

  static Uint8List _aesGcmProcess(
    bool forEncryption,
    Uint8List key,
    Uint8List iv,
    Uint8List input,
  ) {
    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(key),
      128,
      iv,
      Uint8List(0),
    ); // 128-bit auth tag
    cipher.init(forEncryption, params);

    final out = Uint8List(cipher.getOutputSize(input.length));
    var len = cipher.processBytes(input, 0, input.length, out, 0);
    len += cipher.doFinal(out, len);
    return out.sublist(0, len);
  }

  static String globalEncryption(String message, String userName, String pwd) {
    String encryptedMessage = encryptMessage(message, pwd);
    String encryptedUserName = encryptMessage(userName, pwd).substring(0, 10);
    return encryptedMessage + encryptedUserName;
  }

  static String? globalDecryption(
    String encryptedData,
    String userName,
    String pwd,
  ) {
    String encryptedMessage = encryptedData.substring(
      0,
      encryptedData.length - 10,
    );
    String encryptedUserName = encryptedData.substring(
      encryptedData.length - 10,
    );
    String tmp = encryptMessage(userName, pwd).substring(0, 10);
    if (tmp == encryptedUserName) {
      return decryptMessage(encryptedMessage, pwd);
    } else {
      return null;
    }
  }

  static String encryptMessage(String message, String pwd) {
    final salt = _randomBytes(16); // 16 bytes de sel
    final iv = _randomBytes(12); // 12 bytes recommandés pour GCM
    final key = _deriveKey(pwd, salt, iterations: 10000, keyLength: 32);

    final plaintext = Uint8List.fromList(utf8.encode(message));
    final cipherText = _aesGcmProcess(true, key, iv, plaintext);

    final out = Uint8List(salt.length + iv.length + cipherText.length)
      ..setRange(0, salt.length, salt)
      ..setRange(salt.length, salt.length + iv.length, iv)
      ..setRange(
        salt.length + iv.length,
        salt.length + iv.length + cipherText.length,
        cipherText,
      );
    String res = base64Encode(out);
    return res;
  }

  // Déchiffre la string Base64 générée ci‑dessus. En cas de mot de passe incorrect, retourne une chaîne vide.
  static String decryptMessage(String encryptedMessage, String pwd) {
    try {
      final data = base64Decode(encryptedMessage);
      if (data.length < 16 + 12 + 16)
        return ''; // trop court pour salt+iv+tag au minimum

      final salt = data.sublist(0, 16);
      final iv = data.sublist(16, 16 + 12);
      final cipherText = data.sublist(16 + 12);

      final key = _deriveKey(pwd, salt, iterations: 10000, keyLength: 32);
      final plain = _aesGcmProcess(false, key, iv, cipherText);
      return utf8.decode(plain);
    } catch (_) {
      return '';
    }
  }
}
