import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class StorageService {
  final firebase_storage.FirebaseStorage _storage =
      firebase_storage.FirebaseStorage.instance;

  Future<String> uploadStoryImage(Uint8List data, String userId) async {
    // caminho padrão tipo Instagram
    final fileName =
        'stories/${userId}-${DateTime.now().millisecondsSinceEpoch}.jpg';

    final ref = _storage.ref().child(fileName);

    final metadata = firebase_storage.SettableMetadata(
      contentType: 'image/jpeg',
    );

    final uploadTask = ref.putData(data, metadata);
    final snapshot = await uploadTask;

    final url = await snapshot.ref.getDownloadURL();
    return url;
  }
}
