import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:temporary_vault/constants/helper.dart';
import 'package:temporary_vault/models/data.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Accès direct à la collection "user_data"
  CollectionReference<Map<String, dynamic>> get userDataCollection =>
      _db.collection('user_data');

  Future<Data> getCurrentUserData(String mail) async {
    try {
      final querySnapshot = await userDataCollection
          .where('user', isEqualTo: mail)
          .get();
      final query = querySnapshot.docs.map((doc) {
        final data = doc.data();
        final keys = data.keys.toList()..sort();
        final values = keys.map((k) => '$k: ${data[k]}').join(' • ');
        return '${doc.id}${values.isNotEmpty ? ' • $values' : ''}';
      }).toList();
      List<String> list = query[0]
          .split(RegExp(r'\s*•\s*'))
          .map((p) => p.trim())
          .toList();
      Data dt = Data(
        mail: list[4].split(": ")[1],
        deadline: fromIntToDateTime(int.parse(list[1].split(': ')[1])),
        message: list[3].split(': ')[1],
        locked: bool.parse(list[2].split(': ')[1]),
      );
      return dt;
    } catch (e) {
      // log et renvoie une liste vide en cas d'erreur
      // print/debugging léger pour aide au dev
      return Data(
        mail: "",
        deadline: DateTime.now(),
        message: '',
        locked: false,
      );
    }
  }

  // Nouvelle méthode : insère une List<dynamic> dans la collection "user_data".
  // Chaque élément de la liste devient une clé 'field_0', 'field_1', ...
  // Optionnel : préciser l'email de l'utilisateur via le paramètre 'mail'.
  // Retourne l'id du document créé, ou null si erreur.
  Future<String?> createVault(Data dt, String pwd) async {
    try {
      final Map<String, dynamic> data = {};
      data['deadline'] = dt.deadline.millisecondsSinceEpoch;
      String encryptedMessage = Helper.globalEncryption(
        dt.message,
        dt.mail,
        pwd,
      );
      data['message'] = encryptedMessage;
      data['user'] = dt.mail;
      data['locked'] = true;
      final docRef = await userDataCollection.add(data);
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  Future<bool> hasVault(String mail) async {
    final data = await getCurrentUserData(mail);
    return data.mail != "";
  }

  Future<void> unlockUser(String mail) async {
    try {
      final querySnapshot = await userDataCollection
          .where('user', isEqualTo: mail)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs[0].id;
        await userDataCollection.doc(docId).update({'locked': false});
      }
    } catch (e) {
      print('DatabaseHelper.unlockUser error: $e');
    }
  }

  Future<bool> isDeadlinePassed(String mail) async {
    final data = await getCurrentUserData(mail);
    DateTime deadline = data.deadline;
    DateTime now = DateTime.now();
    return now.isAfter(deadline);
  }

  DateTime fromIntToDateTime(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  int fromDateTimeToInt(DateTime dateTime) {
    return dateTime.millisecondsSinceEpoch;
  }
}
