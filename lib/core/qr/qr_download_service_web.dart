// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:qr_flutter/qr_flutter.dart';

Future<bool> downloadQrImage({
  required String data,
  required String filename,
}) async {
  final painter = QrPainter(
    data: data,
    version: QrVersions.auto,
    gapless: true,
    errorCorrectionLevel: QrErrorCorrectLevel.L,
  );
  final byteData = await painter.toImageData(
    1024,
    format: ui.ImageByteFormat.png,
  );
  if (byteData == null) return false;

  final bytes = Uint8List.view(byteData.buffer);
  final blob = html.Blob(<Object>[bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return true;
}
