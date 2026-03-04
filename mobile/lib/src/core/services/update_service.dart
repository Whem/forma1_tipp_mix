import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const String _baseUrl = 'https://liggin.xyz';
const String _versionUrl = '$_baseUrl/api/version';

final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

class AppVersion {
  final String version;
  final int build;
  final String apkUrl;

  AppVersion({required this.version, required this.build, required this.apkUrl});

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      version: json['version'] as String? ?? '0.0.0',
      build: json['build'] as int? ?? 0,
      apkUrl: json['apk_url'] as String? ?? '',
    );
  }
}

class UpdateService {
  Future<AppVersion?> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse(_versionUrl)).timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode != 200) return null;

      final remote = AppVersion.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;

      if (remote.build > currentBuild) {
        return remote;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> showUpdateDialog(BuildContext context, AppVersion update) async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Frissítés elérhető'),
        content: Text(
          'Új verzió: v${update.version}\n\nSzeretnéd letölteni és telepíteni?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Később'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Frissítés'),
          ),
        ],
      ),
    );

    if (accepted == true) {
      final url = update.apkUrl.startsWith('http')
          ? update.apkUrl
          : '$_baseUrl${update.apkUrl}';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
