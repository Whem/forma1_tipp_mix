import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static Future<void> shareWidget(GlobalKey key, String text) async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/f1_tipp_share.png')
        .writeAsBytes(pngBytes);

    await Share.shareXFiles([XFile(file.path)], text: text);
  }

  static String predictionShareText(
    String raceName,
    String p1,
    String p2,
    String p3,
  ) {
    return '🏎️ F1 Tipp Mix - $raceName\n'
        '🥇 $p1\n🥈 $p2\n🥉 $p3\n\n'
        '#F1TippMix #F1 #Formula1';
  }

  static String resultShareText(String raceName, int points, int rank) {
    return '🏁 F1 Tipp Mix - $raceName\n'
        '📊 $points pont | #$rank helyezés\n\n'
        '#F1TippMix #F1';
  }
}

final shareServiceProvider = Provider<ShareService>((ref) => ShareService());
