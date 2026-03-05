import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:forma1_tipp/src/features/auth/data/auth_repository.dart';
import 'package:forma1_tipp/src/features/gamification/domain/achievement.dart';

const String _fileServerBase = 'https://f1.liggin.xyz';

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

      final pathLower = imageFile.path.toLowerCase();
      final String ext;
      final MediaType mediaType;
      if (pathLower.endsWith('.jpg') || pathLower.endsWith('.jpeg')) {
        ext = 'jpg';
        mediaType = MediaType('image', 'jpeg');
      } else if (pathLower.endsWith('.webp')) {
        ext = 'webp';
        mediaType = MediaType('image', 'webp');
      } else if (pathLower.endsWith('.png')) {
        ext = 'png';
        mediaType = MediaType('image', 'png');
      } else {
        final bytes = await imageFile.openRead(0, 4).first;
        if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
          ext = 'jpg';
          mediaType = MediaType('image', 'jpeg');
        } else {
          ext = 'png';
          mediaType = MediaType('image', 'png');
        }
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'avatar',
          imageFile.path,
          contentType: mediaType,
        ),
      );

      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Upload timed out'),
      );
      if (response.statusCode == 200) {
        await response.stream.drain();
        final cacheBuster = DateTime.now().millisecondsSinceEpoch;
        final url = '$_fileServerBase/avatars/$uid.$ext?v=$cacheBuster';
        await _firestore.collection('users').doc(uid).update({
          'avatarUrl': url,
        });
        return url;
      } else {
        final body = await response.stream.bytesToString();
        throw Exception('Upload failed (HTTP ${response.statusCode}): $body');
      }
    } catch (e) {
      rethrow;
    }
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
