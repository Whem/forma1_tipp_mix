import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:forma1_tipp/src/features/auth/data/auth_repository.dart';
import 'package:forma1_tipp/src/features/gamification/domain/achievement.dart';

const String _fileServerBase = 'https://liggin.xyz';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(firestore: ref.watch(firestoreProvider));
});

class ProfileRepository {
  ProfileRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<String?> uploadAvatar(String uid, File imageFile) async {
    try {
      final uri =
          Uri.parse('$_fileServerBase/upload/avatar?uid=$uid');
      final request = http.MultipartRequest('POST', uri);
      final ext = imageFile.path.split('.').last.toLowerCase();
      final mediaType = ext == 'jpg' || ext == 'jpeg'
          ? MediaType('image', 'jpeg')
          : ext == 'webp'
              ? MediaType('image', 'webp')
              : MediaType('image', 'png');

      request.files.add(
        await http.MultipartFile.fromPath(
          'avatar',
          imageFile.path,
          contentType: mediaType,
        ),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        await response.stream.drain();
        final url = '$_fileServerBase/avatars/$uid.$ext';
        await _firestore.collection('users').doc(uid).update({
          'avatarUrl': url,
        });
        return url;
      }
    } catch (_) {}
    return null;
  }

  Future<void> updateLanguage(String uid, String lang) {
    return _firestore.collection('users').doc(uid).update({
      'language': lang,
    });
  }

  Future<List<Achievement>> getUserAchievements(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final data = userDoc.data();
    if (data == null) return [];

    final ids = List<String>.from(data['achievementIds'] as List? ?? []);
    if (ids.isEmpty) return [];

    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
    }

    final results = <Achievement>[];
    for (final chunk in chunks) {
      final snap = await _firestore
          .collection('achievements')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(
        snap.docs.map((doc) => Achievement.fromFirestore(doc.data(), doc.id)),
      );
    }
    return results;
  }
}
