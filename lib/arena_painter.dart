import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_entities.dart';
import 'enemy_types.dart';

class ArenaPainter extends CustomPainter {
  ArenaPainter(
    this.px,
    this.py,
    this.enemies,
    this.orbs,
    this.shots,
    this.damageNumbers,
    this.shockwaves,
    this.trolleyHitTimers,
    this.swingTimer,
    this.swingAngle,
    this.hitTimer,
    this.trolleyAngle,
    this.hasTrolleys,
    this.teaSplashTimer,
    this.teaSplashX,
    this.teaSplashY,
    this.weapon,
    this.benches,
    this.trees,
    this.lampPosts,
    this.pigeons,
    this.walkTime,
    this.paths,
    this.picnicTables,
  );
  final double px, py;
  final List<Enemy> enemies;
  final List<Orb> orbs;
  final List<Shot> shots;
  final List<DamageNumber> damageNumbers;
  final List<Shockwave> shockwaves;
  final List<double> trolleyHitTimers;
  final double swingTimer;
  final double swingAngle;
  final double hitTimer;
  final double trolleyAngle;
  final bool hasTrolleys;
  final double teaSplashTimer;
  final double teaSplashX;
  final double teaSplashY;
  final String weapon;
  final List<ParkBench> benches;
  final List<ParkTree> trees;
  final List<LampPost> lampPosts;
  final List<Pigeon> pigeons;
  final double walkTime;
  final List<ParkPath> paths;
  final List<PicnicTable> picnicTables;
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xff6fa05b);
    canvas.drawRect(Offset.zero & size, bg);
    final area = Rect.fromLTWH(0, 76, size.width, size.height - 76);
    final worldScale = math.min(size.width, size.height - 76);
    final worldCenter = Offset(size.width / 2, 76 + (size.height - 76) / 2);
    Offset at(double x, double y) => Offset(
      worldCenter.dx + (x - px) * worldScale,
      worldCenter.dy + (y - py) * worldScale,
    );
    canvas.drawRect(
      area,
      Paint()..color = const Color(0xff7cac63).withValues(alpha: .35),
    );
    canvas.save();
    canvas.clipRect(area);
    final pathPaint = Paint()
      ..color = const Color(0xffb8a879).withValues(alpha: .4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = worldScale * .22;
    canvas.drawLine(at(-5, 0), at(5, 0), pathPaint);
    canvas.drawLine(at(0, -5), at(0, 5), pathPaint);
    final grass = Paint()
      ..color = const Color(0xff4f8049).withValues(alpha: .3);
    for (var x = -6.0; x <= 6; x += .25) {
      for (var y = -6.0; y <= 6; y += .25) {
        final p = at(x, y);
        if (p.dx > 0 && p.dx < size.width && p.dy > 76 && p.dy < size.height) {
          canvas.drawCircle(p, 1.2, grass);
        }
      }
    }
    for (final path in paths) {
      final rect = Rect.fromCenter(
        center: at(path.x, path.y),
        width: path.width * worldScale,
        height: path.height * worldScale,
      );
      canvas.drawRect(rect, Paint()..color = const Color(0xffc7b486));
      canvas.drawRect(
        rect.deflate(3),
        Paint()..color = const Color(0xffd5c596).withValues(alpha: .6),
      );
    }
    for (final tree in trees) {
      final p = at(tree.x, tree.y);
      final radius = tree.size * worldScale * .22;
      canvas.drawCircle(
        p + Offset(5, radius * .7),
        radius * 1.15,
        Paint()..color = const Color(0xff385f3b).withValues(alpha: .35),
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: p + Offset(0, radius * .65),
          width: radius * .25,
          height: radius * 1.25,
        ),
        Paint()..color = const Color(0xff765039),
      );
      canvas.drawCircle(p, radius, Paint()..color = const Color(0xff2f713d));
      canvas.drawCircle(
        p + Offset(-radius * .55, radius * .12),
        radius * .7,
        Paint()..color = const Color(0xff3f8448),
      );
      canvas.drawCircle(
        p + Offset(radius * .52, radius * .08),
        radius * .65,
        Paint()..color = const Color(0xff4a914c),
      );
    }
    for (final table in picnicTables) {
      final p = at(table.x, table.y);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(table.rotation);
      final wood = Paint()..color = const Color(0xff9a633d);
      canvas.drawRect(const Rect.fromLTWH(-25, -5, 50, 10), wood);
      canvas.drawRect(const Rect.fromLTWH(-25, 16, 50, 7), wood);
      canvas.drawRect(const Rect.fromLTWH(-17, -15, 34, 5), wood);
      canvas.drawLine(
        const Offset(-17, 7),
        const Offset(-10, 25),
        wood..strokeWidth = 3,
      );
      canvas.drawLine(
        const Offset(17, 7),
        const Offset(10, 25),
        wood..strokeWidth = 3,
      );
      canvas.restore();
    }
    for (final lamp in lampPosts) {
      final p = at(lamp.x, lamp.y);
      final post = Paint()
        ..color = const Color(0xff424b4d)
        ..strokeWidth = 4;
      canvas.drawLine(p + const Offset(0, 18), p + const Offset(0, -28), post);
      canvas.drawLine(
        p + const Offset(-8, -28),
        p + const Offset(8, -28),
        post,
      );
      canvas.drawCircle(
        p + const Offset(0, -30),
        7,
        Paint()..color = const Color(0xffffe19a).withValues(alpha: .8),
      );
    }
    for (final pigeon in pigeons) {
      final p = at(pigeon.x, pigeon.y);
      final wing = pigeon.startled > 0
          ? math.sin(pigeon.startled * 18).abs() * 5
          : 0.0;
      final bird = Paint()..color = const Color(0xffd9dedb);
      canvas.drawOval(Rect.fromCenter(center: p, width: 14, height: 9), bird);
      canvas.drawCircle(p + const Offset(7, -2), 3, bird);
      canvas.drawLine(
        p + Offset(-3, -2 - wing),
        p + Offset(-9, -8 - wing),
        Paint()
          ..color = const Color(0xff8a9693)
          ..strokeWidth = 3,
      );
      canvas.drawLine(
        p + Offset(0, -2 + wing),
        p + Offset(6, -8 + wing),
        Paint()
          ..color = const Color(0xff8a9693)
          ..strokeWidth = 3,
      );
    }
    for (final bench in benches) {
      final center = at(bench.x, bench.y);
      final rect = Rect.fromCenter(
        center: center,
        width: bench.width * worldScale,
        height: bench.height * worldScale,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        Paint()..color = const Color(0xff754f36),
      );
      final seat = rect.deflate(4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(seat, const Radius.circular(3)),
        Paint()..color = const Color(0xffb77b4e),
      );
      final back = Paint()
        ..color = const Color(0xff563b2c)
        ..strokeWidth = 4;
      if (bench.width > bench.height) {
        canvas.drawLine(
          Offset(rect.left, rect.center.dy - 5),
          Offset(rect.right, rect.center.dy - 5),
          back,
        );
      } else {
        canvas.drawLine(
          Offset(rect.center.dx - 5, rect.top),
          Offset(rect.center.dx - 5, rect.bottom),
          back,
        );
      }
    }
    for (final orb in orbs) {
      final p = at(orb.x, orb.y);
      if (orb.type == 3) {
        canvas.drawCircle(
          p,
          18,
          Paint()..color = const Color(0xffd96b34).withValues(alpha: .22),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: p, width: 18, height: 25),
            const Radius.circular(4),
          ),
          Paint()..color = const Color(0xffb94d2b),
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: p + const Offset(0, -4),
            width: 12,
            height: 8,
          ),
          Paint()..color = const Color(0xfff0d7a0),
        );
        canvas.drawCircle(
          p + const Offset(0, -4),
          3,
          Paint()..color = const Color(0xff9b3325),
        );
        canvas.drawLine(
          p + const Offset(-7, 9),
          p + const Offset(7, 9),
          Paint()
            ..color = const Color(0xfff0d7a0)
            ..strokeWidth = 2,
        );
      } else if (orb.type == 2) {
        canvas.drawCircle(
          p,
          18,
          Paint()..color = const Color(0xffd98cff).withValues(alpha: .2),
        );
        canvas.drawCircle(p, 9, Paint()..color = const Color(0xffb45cff));
        canvas.drawCircle(p, 5, Paint()..color = const Color(0xfff0d7ff));
        canvas.drawLine(
          p + const Offset(-8, 0),
          p + const Offset(8, 0),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2,
        );
        canvas.drawLine(
          p + const Offset(0, -8),
          p + const Offset(0, 8),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2,
        );
      } else if (orb.type == 1) {
        final glow = Paint()
          ..color = const Color(0xffd8b15f).withValues(alpha: .18);
        canvas.drawCircle(p, 14, glow);
        final pack = Paint()..color = const Color(0xff6f7650);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: p, width: 18, height: 13),
            const Radius.circular(2),
          ),
          pack,
        );
        canvas.drawLine(
          p + const Offset(-7, -4),
          p + const Offset(7, -4),
          Paint()
            ..color = const Color(0xffaeb27a)
            ..strokeWidth = 2,
        );
        canvas.drawLine(
          p + const Offset(0, -6),
          p + const Offset(0, 6),
          Paint()
            ..color = const Color(0xff4d5538)
            ..strokeWidth = 2,
        );
        canvas.drawRect(
          Rect.fromCenter(center: p + const Offset(0, 1), width: 6, height: 6),
          Paint()..color = const Color(0xffd8b15f),
        );
        canvas.drawLine(
          p + const Offset(-2, 1),
          p + const Offset(2, 1),
          Paint()
            ..color = const Color(0xff6f7650)
            ..strokeWidth = 1,
        );
        canvas.drawLine(
          p + const Offset(0, -1),
          p + const Offset(0, 3),
          Paint()
            ..color = const Color(0xff6f7650)
            ..strokeWidth = 1,
        );
      } else {
        final xpPaint = Paint()..color = const Color(0xffa8ffff);
        if (orb.pulledToPlayer) {
          final player = at(px, py);
          canvas.drawLine(
            p,
            p + (player - p) * .35,
            Paint()
              ..color = Colors.white.withValues(alpha: .7)
              ..strokeWidth = 2,
          );
        }
        canvas.drawCircle(p, 8, xpPaint);
        canvas.drawCircle(
          p,
          18,
          Paint()..color = xpPaint.color.withValues(alpha: .16),
        );
        canvas.drawLine(
          p + const Offset(-6, 0),
          p + const Offset(6, 0),
          Paint()
            ..color = Colors.white.withValues(alpha: .8)
            ..strokeWidth = 2,
        );
        canvas.drawLine(
          p + const Offset(0, -6),
          p + const Offset(0, 6),
          Paint()
            ..color = Colors.white.withValues(alpha: .8)
            ..strokeWidth = 2,
        );
      }
    }
    for (final shot in shots) {
      final p = at(shot.x, shot.y);
      final phase = .72 + math.sin((1 - shot.life) * math.pi * 8).abs() * .28;
      if (shot.weapon == 'Noisy Grandkid') {
        final babyGlow = Paint()
          ..color = const Color(0xffff9a9a).withValues(alpha: .12 * phase);
        canvas.drawCircle(p, 16 + phase * 3, babyGlow);
        canvas.drawCircle(
          p + const Offset(0, -6),
          7 + phase,
          Paint()..color = const Color(0xffffc4a8).withValues(alpha: phase),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: p + const Offset(0, 5),
            width: 13 + phase * 2,
            height: 14 + phase * 2,
          ),
          Paint()..color = const Color(0xffcf6c68).withValues(alpha: phase),
        );
        canvas.drawLine(
          p + const Offset(-7, 2),
          p + const Offset(-11, 8),
          Paint()
            ..color = const Color(0xffffc4a8).withValues(alpha: phase)
            ..strokeWidth = 3,
        );
        canvas.drawLine(
          p + const Offset(7, 2),
          p + const Offset(11, 8),
          Paint()
            ..color = const Color(0xffffc4a8).withValues(alpha: phase)
            ..strokeWidth = 3,
        );
        canvas.drawCircle(
          p + const Offset(-3, -7),
          1.5,
          Paint()..color = Colors.black87,
        );
        canvas.drawCircle(
          p + const Offset(3, -7),
          1.5,
          Paint()..color = Colors.black87,
        );
        canvas.drawCircle(
          p + const Offset(0, -3),
          2.5,
          Paint()..color = const Color(0xfff1d8d0).withValues(alpha: phase),
        );
      } else if (shot.weapon == 'Thermos Tea') {
        final tea = Paint()
          ..color = const Color(0xffc88c62).withValues(alpha: phase);
        canvas.drawCircle(
          p,
          18 + phase * 4,
          Paint()
            ..color = const Color(0xffffc58a).withValues(alpha: .12 * phase),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: p,
            width: 12 + phase * 2,
            height: 16 + phase * 2,
          ),
          tea,
        );
        canvas.drawArc(
          Rect.fromCenter(center: p + const Offset(7, 0), width: 9, height: 10),
          -math.pi / 2,
          math.pi,
          false,
          tea
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: p + const Offset(-3, -11),
            width: 8,
            height: 14,
          ),
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = Colors.white.withValues(alpha: .5 * phase)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      } else if (shot.weapon == 'Pocket Radio') {
        final pulse = Paint()
          ..color = const Color(0xffd4b35e).withValues(alpha: .65 * phase)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: p, width: 18, height: 13),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xff6d5f3f).withValues(alpha: phase),
        );
        canvas.drawLine(
          p + const Offset(-6, -6),
          p + const Offset(-10, -14),
          pulse,
        );
        canvas.drawArc(
          Rect.fromCircle(center: p, radius: 15 + phase * 5),
          -1.1,
          2.2,
          false,
          pulse,
        );
      } else if (shot.weapon == 'Garden Hose') {
        final water = Paint()
          ..color = const Color(0xff70d0e0).withValues(alpha: .75 * phase)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        canvas.drawCircle(
          p,
          8 + phase * 3,
          Paint()
            ..color = const Color(0xff70d0e0).withValues(alpha: .14 * phase),
        );
        canvas.drawLine(
          p + const Offset(-10, 0),
          p + const Offset(10, 0),
          water,
        );
        canvas.drawCircle(
          p,
          4,
          Paint()..color = const Color(0xffd5f7ff).withValues(alpha: phase),
        );
      } else if (shot.weapon == 'Bingo Blaster') {
        canvas.drawCircle(
          p,
          7 + phase * 2,
          Paint()..color = const Color(0xfff0e2c0).withValues(alpha: phase),
        );
        canvas.drawCircle(
          p,
          3,
          Paint()..color = const Color(0xffb54d50).withValues(alpha: phase),
        );
        canvas.drawCircle(
          p,
          1,
          Paint()..color = const Color(0xfff0e2c0).withValues(alpha: phase),
        );
      } else if (shot.weapon == 'Reading Glasses') {
        final beam = Paint()
          ..color = const Color(0xff9ca8d4).withValues(alpha: .6 * phase)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        canvas.drawCircle(p, 7, beam);
        canvas.drawCircle(
          p,
          14 + phase * 3,
          Paint()
            ..color = const Color(0xff9ca8d4).withValues(alpha: .12 * phase),
        );
      } else {
        final candy = Paint()
          ..color = const Color(0xffffd477).withValues(alpha: phase);
        canvas.drawCircle(p, 7 + phase * 2, candy);
        canvas.drawCircle(
          p,
          13 + phase * 3,
          Paint()
            ..color = const Color(0xffffd477).withValues(alpha: .12 * phase),
        );
        canvas.drawLine(
          p + const Offset(-10, 0),
          p + const Offset(-5, 0),
          Paint()
            ..color = const Color(0xffd98f4a).withValues(alpha: phase)
            ..strokeWidth = 3,
        );
        canvas.drawLine(
          p + const Offset(5, 0),
          p + const Offset(10, 0),
          Paint()
            ..color = const Color(0xffd98f4a).withValues(alpha: phase)
            ..strokeWidth = 3,
        );
      }
    }
    for (final shockwave in shockwaves) {
      final progress = 1 - shockwave.life / 2.4;
      final center = at(shockwave.x, shockwave.y);
      final radius = 18 + progress * 180;
      final alpha = (shockwave.life / 2.4).clamp(0.0, 1.0);
      final pulse = Paint()
        ..color = const Color(0xffd4b35e).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7;
      canvas.drawCircle(center, radius, pulse);
      canvas.drawCircle(
        center,
        radius * .72,
        Paint()..color = const Color(0xffffe29a).withValues(alpha: .16 * alpha),
      );
      canvas.drawCircle(
        center,
        radius * .45,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xfffff0b3).withValues(alpha: .55 * alpha),
      );
    }
    for (final e in enemies) {
      final p = at(e.x, e.y);
      if (e.type == EnemyType.scooterTeen) {
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.scale(e.facingRight ? 1 : -1, 1);
        canvas.translate(-p.dx, -p.dy);
      }
      final stunned = e.stunned > 0;
      final color = e.type == EnemyType.scooterTeen
          ? const Color(0xffd08b52)
          : e.type == EnemyType.vapeTeen
          ? const Color(0xff84aa86)
          : e.type == EnemyType.goth
          ? const Color(0xff536b80)
          : const Color(0xffb86a65);
      canvas.drawCircle(
        p,
        stunned ? 20 : 16,
        Paint()
          ..color = (stunned ? const Color(0xffffe29a) : color).withValues(
            alpha: stunned ? .24 : .16,
          ),
      );
      final body = Paint()
        ..color = stunned ? color.withValues(alpha: .7) : color;
      if (e.type == EnemyType.scooterTeen) {
        canvas.drawOval(
          Rect.fromCenter(
            center: p + const Offset(0, 6),
            width: 17,
            height: 22,
          ),
          body,
        );
        canvas.drawLine(
          p + const Offset(-7, 7),
          p + const Offset(-11, 17),
          Paint()
            ..color = color
            ..strokeWidth = 4,
        );
        canvas.drawLine(
          p + const Offset(7, 7),
          p + const Offset(11, 17),
          Paint()
            ..color = color
            ..strokeWidth = 4,
        );
      } else if (e.type == EnemyType.vapeTeen) {
        final hoodie = Path()
          ..moveTo(p.dx - 12, p.dy + 15)
          ..lineTo(p.dx - 9, p.dy - 1)
          ..quadraticBezierTo(p.dx, p.dy - 8, p.dx + 9, p.dy - 1)
          ..lineTo(p.dx + 12, p.dy + 15)
          ..close();
        canvas.drawPath(hoodie, body);
        canvas.drawLine(
          p + const Offset(-8, 3),
          p + const Offset(-14, 11),
          Paint()
            ..color = color
            ..strokeWidth = 4,
        );
        canvas.drawLine(
          p + const Offset(8, 3),
          p + const Offset(14, 11),
          Paint()
            ..color = color
            ..strokeWidth = 4,
        );
      } else if (e.type == EnemyType.goth) {
        final coat = Path()
          ..moveTo(p.dx - 9, p.dy - 2)
          ..lineTo(p.dx - 14, p.dy + 17)
          ..lineTo(p.dx + 14, p.dy + 17)
          ..lineTo(p.dx + 9, p.dy - 2)
          ..close();
        canvas.drawPath(coat, body);
        canvas.drawLine(
          p + const Offset(-8, 4),
          p + const Offset(-14, 15),
          Paint()
            ..color = color
            ..strokeWidth = 4,
        );
        canvas.drawLine(
          p + const Offset(8, 4),
          p + const Offset(14, 15),
          Paint()
            ..color = color
            ..strokeWidth = 4,
        );
        canvas.drawLine(
          p + const Offset(0, 5),
          p + const Offset(0, 17),
          Paint()
            ..color = const Color(0xff171721)
            ..strokeWidth = 2,
        );
      } else {
        final hoodie = Path()
          ..moveTo(p.dx - 13, p.dy + 16)
          ..lineTo(p.dx - 11, p.dy - 3)
          ..quadraticBezierTo(p.dx, p.dy - 12, p.dx + 11, p.dy - 3)
          ..lineTo(p.dx + 13, p.dy + 16)
          ..close();
        canvas.drawPath(hoodie, body);
        canvas.drawLine(
          p + const Offset(-8, 4),
          p + const Offset(-15, 13),
          Paint()
            ..color = color
            ..strokeWidth = 5,
        );
        canvas.drawLine(
          p + const Offset(8, 4),
          p + const Offset(15, 13),
          Paint()
            ..color = color
            ..strokeWidth = 5,
        );
      }
      canvas.drawCircle(
        p + const Offset(0, -6),
        9,
        Paint()..color = const Color(0xffd99d72),
      );
      final face = Paint()..color = Colors.white70;
      canvas.drawCircle(p + const Offset(-3, -2), 2, face);
      canvas.drawCircle(p + const Offset(3, -2), 2, face);
      if (stunned) {
        canvas.drawArc(
          Rect.fromCircle(center: p + const Offset(0, -22), radius: 8),
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = const Color(0xffffe29a)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
        );
        canvas.drawCircle(
          p + const Offset(-8, -24),
          2,
          Paint()..color = const Color(0xffffe29a),
        );
        canvas.drawCircle(
          p + const Offset(8, -24),
          2,
          Paint()..color = const Color(0xffffe29a),
        );
      }
      if (e.type == EnemyType.scooterTeen) {
        final wheel = Paint()
          ..color = const Color(0xff24313b)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(p + const Offset(-11, 18), 4, wheel);
        canvas.drawCircle(p + const Offset(11, 18), 4, wheel);
        canvas.drawLine(
          p + const Offset(-11, 18),
          p + const Offset(10, 13),
          wheel,
        );
        canvas.drawLine(
          p + const Offset(0, 0),
          p + const Offset(10, 13),
          wheel,
        );
        canvas.drawLine(p + const Offset(5, 5), p + const Offset(13, 5), wheel);
        canvas.drawLine(
          p + const Offset(-13, 13),
          p + const Offset(13, 13),
          Paint()
            ..color = const Color(0xff59d0dc)
            ..strokeWidth = 3,
        );
      } else if (e.type == EnemyType.vapeTeen) {
        final cloud = Paint()
          ..color = const Color(0xffc7d7c2).withValues(alpha: .65);
        canvas.drawCircle(p + const Offset(12, -12), 4, cloud);
        canvas.drawCircle(p + const Offset(17, -17), 3, cloud);
        canvas.drawCircle(p + const Offset(20, -22), 2, cloud);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: p + const Offset(13, 8),
              width: 4,
              height: 12,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xffd7e3e1),
        );
      } else if (e.type == EnemyType.goth) {
        final hair = Paint()..color = const Color(0xff20212a);
        final spikes = Path()
          ..moveTo(p.dx - 12, p.dy - 5)
          ..lineTo(p.dx - 16, p.dy - 18)
          ..lineTo(p.dx - 8, p.dy - 12)
          ..lineTo(p.dx - 4, p.dy - 20)
          ..lineTo(p.dx + 1, p.dy - 12)
          ..lineTo(p.dx + 9, p.dy - 19)
          ..lineTo(p.dx + 12, p.dy - 3)
          ..close();
        canvas.drawPath(spikes, hair);
        canvas.drawLine(
          p + const Offset(-11, 6),
          p + const Offset(11, 6),
          Paint()
            ..color = const Color(0xffd05c9d)
            ..strokeWidth = 2,
        );
      } else {
        final hood = Paint()
          ..color = const Color(0xff8e454e).withValues(alpha: .9);
        canvas.drawArc(
          Rect.fromCircle(center: p + const Offset(0, -5), radius: 11),
          math.pi,
          math.pi,
          false,
          hood
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      }
      if (e.type == EnemyType.scooterTeen) canvas.restore();
    }
    final g = at(px, py);
    if (teaSplashTimer > 0) {
      final splashProgress = 1 - teaSplashTimer / 2.8;
      final splashAlpha = math.min(1.0, .35 + teaSplashTimer / 2.8);
      final splash = at(teaSplashX, teaSplashY);
      final radius = 38 + splashProgress * 108;
      canvas.drawCircle(
        splash,
        radius,
        Paint()
          ..color = const Color(0xffffc58a)
              .withValues(alpha: .12 * splashAlpha),
      );
      canvas.drawCircle(
        splash,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = const Color(0xffc88c62).withValues(alpha: .9 * splashAlpha),
      );
      canvas.drawCircle(
        splash,
        radius * .72,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xffffd09a).withValues(alpha: .6 * splashAlpha),
      );
      canvas.drawOval(
        Rect.fromCenter(center: splash, width: 34, height: 24),
        Paint()
          ..color = const Color(0xff9a5d38).withValues(alpha: .9 * splashAlpha),
      );
      for (var i = 0; i < 4; i++) {
        final steamX = splash.dx - 18 + i * 12;
        final steamY = splash.dy - 26 - math.sin((splashProgress * 8) + i) * 8;
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(steamX, steamY),
            width: 12,
            height: 28,
          ),
          math.pi,
          math.pi,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Colors.white.withValues(alpha: .55 * splashAlpha),
        );
      }
    }
    for (final damage in damageNumbers) {
      final alpha = math.min(1.0, damage.life * 3);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '-${damage.amount}',
          style: TextStyle(
            color: damage.color.withValues(alpha: alpha),
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        at(damage.x, damage.y) - Offset(textPainter.width / 2, 20),
      );
    }
    if (hasTrolleys) {
      for (var i = 0; i < 5; i++) {
        final angle = trolleyAngle + i * math.pi * 2 / 5;
        final trolley = at(
          px + math.cos(angle) * (.105 + i * 0.0),
          py + math.sin(angle) * (.105 + i * 0.0),
        );
        final hitPulse = trolleyHitTimers[i] > 0
            ? math.sin((trolleyHitTimers[i] / .24) * math.pi)
            : 0;
        final opacity = 0.72 + hitPulse * .28;
        final bag = Paint()
          ..color = const Color(0xff2876a2).withValues(alpha: opacity);
        canvas.drawCircle(
          trolley,
          15 + hitPulse * 5,
          Paint()
            ..color = const Color(0xff9ed0e5)
                .withValues(alpha: .12 + hitPulse * .2),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: trolley + const Offset(0, -2),
              width: 22,
              height: 20,
            ),
            const Radius.circular(4),
          ),
          bag,
        );
        canvas.drawLine(
          trolley + const Offset(-8, -12),
          trolley + const Offset(8, -12),
          Paint()
            ..color = const Color(0xffc7d7d4).withValues(alpha: opacity)
            ..strokeWidth = 2,
        );
        canvas.drawLine(
          trolley + const Offset(-8, -12),
          trolley + const Offset(-10, -3),
          Paint()
            ..color = const Color(0xffc7d7d4).withValues(alpha: opacity)
            ..strokeWidth = 2,
        );
        canvas.drawLine(
          trolley + const Offset(8, -12),
          trolley + const Offset(10, -3),
          Paint()
            ..color = const Color(0xffc7d7d4).withValues(alpha: opacity)
            ..strokeWidth = 2,
        );
        canvas.drawLine(
          trolley + const Offset(-7, 3),
          trolley + const Offset(7, 3),
          Paint()
            ..color = const Color(0xff8fc0d1).withValues(alpha: opacity)
            ..strokeWidth = 1,
        );
        canvas.drawCircle(
          trolley + const Offset(-8, 11),
          4,
          Paint()..color = const Color(0xff3d464b).withValues(alpha: opacity),
        );
        canvas.drawCircle(
          trolley + const Offset(8, 11),
          4,
          Paint()..color = const Color(0xff3d464b).withValues(alpha: opacity),
        );
      }
    }
    final hitPulse = hitTimer > 0 ? math.sin((hitTimer / .2) * math.pi) : 0;
    canvas.drawCircle(
      g,
      27 + hitPulse * 8,
      Paint()
        ..color =
            (hitPulse > 0 ? const Color(0xffef6a62) : const Color(0xffe6a84d))
                .withValues(alpha: .12 + hitPulse * .18),
    );
    if (hitPulse > 0) {
      canvas.drawCircle(
        g,
        26 + hitPulse * 5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xffef6a62).withValues(alpha: hitPulse * .8),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: g + const Offset(0, 9), width: 25, height: 27),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0xffb98d68),
    );
    final stride = math.sin(walkTime) * 4;
    canvas.drawLine(
      g + Offset(-8, 20 + stride),
      g + Offset(-11, 28 + stride),
      Paint()
        ..color = const Color(0xff292b30)
        ..strokeWidth = 5,
    );
    canvas.drawLine(
      g + Offset(8, 20 - stride),
      g + Offset(11, 28 - stride),
      Paint()
        ..color = const Color(0xff292b30)
        ..strokeWidth = 5,
    );
    canvas.drawCircle(
      g,
      18 + hitPulse * 2,
      Paint()..color = const Color(0xffd9a06a),
    );
    canvas.drawCircle(
      g + const Offset(0, -14),
      13 + hitPulse * 1.5,
      Paint()..color = const Color(0xffe5b789),
    );
    final cap = Paint()..color = const Color(0xff62605a);
    canvas.drawOval(
      Rect.fromCenter(center: g + const Offset(0, -27), width: 29, height: 9),
      cap,
    );
    canvas.drawArc(
      Rect.fromCenter(center: g + const Offset(0, -26), width: 22, height: 13),
      math.pi,
      math.pi,
      false,
      cap..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      g + const Offset(-5, -17),
      2,
      Paint()..color = Colors.black87,
    );
    canvas.drawCircle(
      g + const Offset(5, -17),
      2,
      Paint()..color = Colors.black87,
    );
    final cane = Paint()
      ..color = const Color(0xff9f6b49)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final caneAngle = swingTimer > 0 ? swingAngle - math.atan2(21, 13) : 0.0;
    canvas.save();
    canvas.translate(g.dx, g.dy);
    canvas.rotate(caneAngle);
    canvas.drawLine(Offset(14, 3 - stride), Offset(27, 24 - stride), cane);
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(12, 0), radius: 6),
      -.3,
      2.4,
      false,
      cane,
    );
    canvas.restore();
    if (swingTimer > 0) {
      final reach = weapon == 'Upgraded Cane' ? 45.0 : 35.0;
      final swing = Paint()
        ..color = const Color(0xffc28a5c)
        ..style = PaintingStyle.stroke
        ..strokeWidth = weapon == 'Upgraded Cane' ? 7 : 5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: g, radius: reach),
        swingAngle - 1.15,
        2.3,
        false,
        swing,
      );
      if (weapon == 'Upgraded Cane') {
        canvas.drawArc(
          Rect.fromCircle(center: g, radius: reach),
          swingAngle + math.pi - 1.15,
          2.3,
          false,
          swing,
        );
      }
    }
    canvas.drawCircle(
      g + const Offset(-5, -17),
      2,
      Paint()..color = Colors.black87,
    );
    canvas.drawCircle(
      g + const Offset(5, -17),
      2,
      Paint()..color = Colors.black87,
    );
    canvas.drawRect(
      area,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: .08),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ArenaPainter oldDelegate) => true;
}
