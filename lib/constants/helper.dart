class Helper {
  static String encryptMessage(String message, String pwd) {
    // Implémentation simple de chiffrement par décalage (Caesar cipher)
    final shift = pwd.length % 26; // Utiliser la longueur du mot de passe pour le décalage
    final buffer = StringBuffer();

    for (var codeUnit in message.codeUnits) {
      if (codeUnit >= 65 && codeUnit <= 90) {
        // Majuscules
        buffer.writeCharCode(((codeUnit - 65 + shift) % 26) + 65);
      } else if (codeUnit >= 97 && codeUnit <= 122) {
        // Minuscules
        buffer.writeCharCode(((codeUnit - 97 + shift) % 26) + 97);
      } else {
        // Autres caractères restent inchangés
        buffer.writeCharCode(codeUnit);
      }
    }

    return buffer.toString();
  }

  static String decryptMessage(String encryptedMessage, String pwd) {
    final shift = pwd.length % 26; // Utiliser la longueur du mot de passe pour le décalage
    final buffer = StringBuffer();

    for (var codeUnit in encryptedMessage.codeUnits) {
      if (codeUnit >= 65 && codeUnit <= 90) {
        // Majuscules
        buffer.writeCharCode(((codeUnit - 65 - shift + 26) % 26) + 65);
      } else if (codeUnit >= 97 && codeUnit <= 122) {
        // Minuscules
        buffer.writeCharCode(((codeUnit - 97 - shift + 26) % 26) + 97);
      } else {
        // Autres caractères restent inchangés
        buffer.writeCharCode(codeUnit);
      }
    }

    return buffer.toString();
  }
}