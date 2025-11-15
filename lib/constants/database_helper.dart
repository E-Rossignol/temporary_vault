import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Accès direct à la collection "user_data"
  CollectionReference<Map<String, dynamic>> get userDataCollection =>
      _db.collection('user_data');


  Future<List<String>> getCurrentUserData(String mail) async {
    try {
      final querySnapshot = await userDataCollection.where('mail', isEqualTo: mail).get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        final keys = data.keys.toList()..sort();
        final values = keys.map((k) => '$k: ${data[k]}').join(' • ');
        return '${doc.id}${values.isNotEmpty ? ' • $values' : ''}';
      }).toList();
    } catch (e) {
      // log et renvoie une liste vide en cas d'erreur
      // print/debugging léger pour aide au dev
      print('DatabaseHelper.getCurrentUserData error: $e');
      return <String>[];
    }
  }

  // Nouvelle méthode : insère une List<dynamic> dans la collection "user_data".
  // Chaque élément de la liste devient une clé 'field_0', 'field_1', ...
  // Optionnel : préciser l'email de l'utilisateur via le paramètre 'mail'.
  // Retourne l'id du document créé, ou null si erreur.
  Future<String?> insertUserDataFromList(List<dynamic> values, {String? mail}) async {
    try {
      final Map<String, dynamic> data = {};
      for (var i = 0; i < values.length; i++) {
        data['field_$i'] = values[i];
      }
      if (mail != null) data['mail'] = mail;
      data['createdAt'] = FieldValue.serverTimestamp();
      final docRef = await userDataCollection.add(data);
      return docRef.id;
    } catch (e) {
      print('DatabaseHelper.insertUserDataFromList error: $e');
      return null;
    }
  }

  Future<bool> hasVault(String mail) async{
    final data = await getCurrentUserData(mail);
    return data.isNotEmpty;
  }

  Future<bool> isDeadlinePassed(String mail) async{
    final data = await getCurrentUserData(mail);
    DateTime deadline = fromIntToDateTime(int.parse(data[3].split(': ')[1]));
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