import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models.dart';

void _text(Canvas c, String s, double cx, double y, double size, Color color, {FontWeight weight = FontWeight.w800, double maxWidth = 1400}) {
  final tp = TextPainter(text: TextSpan(text: s, style: TextStyle(fontSize: size, color: color, fontWeight: weight)), textDirection: TextDirection.ltr, textAlign: TextAlign.center)..layout(maxWidth: maxWidth);
  tp.paint(c, Offset(cx - tp.width / 2, y));
}

Future<Uint8List> _png(int w, int h, void Function(Canvas c) draw) async {
  final rec = ui.PictureRecorder();
  draw(Canvas(rec));
  final img = await rec.endRecording().toImage(w, h);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<Uint8List> renderCertificate({required String nickname, required String regionName, required String rank, required String emoji, required DateTime date}) =>
    _png(1600, 1130, (c) {
      const w = 1600.0, h = 1130.0;
      c.drawRect(const Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xfffffaf0));
      c.drawRect(const Rect.fromLTWH(40, 40, w - 80, h - 80), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..color = const Color(0xfff59f00));
      c.drawRect(const Rect.fromLTWH(80, 80, w - 160, h - 160), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = const Color(0xff7950f2));
      _text(c, 'GIẤY CHỨNG NHẬN', w / 2, 160, 90, const Color(0xff5f3dc4));
      _text(c, emoji, w / 2, 290, 130, Colors.black);
      _text(c, 'Piano Quest trân trọng chứng nhận nghệ sĩ nhí', w / 2, 470, 44, const Color(0xff495057), weight: FontWeight.w600);
      _text(c, nickname, w / 2, 540, 110, const Color(0xffe64980));
      _text(c, 'đã chinh phục vùng đất “$regionName”', w / 2, 710, 46, const Color(0xff495057), weight: FontWeight.w600);
      _text(c, 'và đạt danh hiệu: $rank', w / 2, 780, 46, const Color(0xff495057), weight: FontWeight.w600);
      _text(c, 'Ngày ${date.day} tháng ${date.month} năm ${date.year}', w / 2, 900, 36, const Color(0xff495057), weight: FontWeight.w500);
      _text(c, '🏅', 260, 880, 90, Colors.black);
      _text(c, '🎹', w - 260, 880, 90, Colors.black);
    });

Future<Uint8List> renderRecap({
  required String nickname, required AvatarConfig avatar, required String monthLabel, required int minutes, required int days,
  required int songs, required int lessons, required int stars, String? topSong, required List<String> badges,
}) =>
    _png(1080, 1920, (c) {
      const w = 1080.0, h = 1920.0;
      c.drawRect(const Rect.fromLTWH(0, 0, w, h), Paint()..shader = const LinearGradient(colors: [Color(0xff4263eb), Color(0xff9775fa), Color(0xfff783ac)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(const Rect.fromLTWH(0, 0, w, h)));
      _text(c, 'Tổng kết $monthLabel', w / 2, 110, 54, Colors.white, weight: FontWeight.w700);
      _text(c, avatar.animal, w / 2, 220, 190, Colors.white);
      _text(c, nickname, w / 2, 470, 96, Colors.white);
      final rows = [('⏱️', '$minutes phút luyện đàn'), ('📅', '$days ngày chăm chỉ'), ('🎵', '$songs lần chơi bài hát'), ('📘', '$lessons bài học'), ('⭐', '$stars ngôi sao')];
      for (var i = 0; i < rows.length; i++) {
        final y = 640.0 + i * 150;
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(120, y, w - 240, 120), const Radius.circular(40)), Paint()..color = Colors.white24);
        _text(c, '${rows[i].$1}  ${rows[i].$2}', w / 2, y + 26, 60, Colors.white);
      }
      if (topSong != null) {
        _text(c, 'Bài hát yêu thích nhất:', w / 2, 1460, 48, Colors.white, weight: FontWeight.w600);
        _text(c, topSong, w / 2, 1530, 64, Colors.white);
      }
      _text(c, badges.take(6).join(' '), w / 2, 1650, 80, Colors.white);
      _text(c, 'Piano Quest – Hành trình phím đàn', w / 2, h - 90, 40, Colors.white, weight: FontWeight.w600);
    });

Rect? shareOrigin(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
}

Future<void> shareImage(BuildContext context, Uint8List png, String fileName, String text) async {
  await SharePlus.instance.share(ShareParams(
    text: text,
    files: [XFile.fromData(png, mimeType: 'image/png', name: fileName)],
    fileNameOverrides: [fileName],
    sharePositionOrigin: shareOrigin(context),
  ));
}

Future<void> shareLink(BuildContext context, String url, String text) async {
  await Clipboard.setData(ClipboardData(text: url));
  if (!context.mounted) return;
  await SharePlus.instance.share(ShareParams(text: '$text $url', sharePositionOrigin: shareOrigin(context)));
}
