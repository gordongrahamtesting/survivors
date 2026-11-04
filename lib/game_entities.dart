import 'package:flutter/material.dart';

import 'enemy_types.dart';

class Enemy {
  Enemy(
    this.x,
    this.y,
    this.type,
    this.maxHp, {
    this.vx = 0,
    this.vy = 0,
    this.trajectoryOnly = false,
  });
  double x;
  double y;
  final EnemyType type;
  final double maxHp;
  double vx;
  double vy;
  bool trajectoryOnly;
  late double hp = maxHp;
  double stunned = 0;
  double teaDamageCooldown = 0;
  double contactCooldown = 0;
}

class ParkBench {
  const ParkBench(this.x, this.y, this.width, this.height);
  final double x;
  final double y;
  final double width;
  final double height;
}

class ParkTree {
  const ParkTree(this.x, this.y, this.size);
  final double x;
  final double y;
  final double size;
}

class LampPost {
  const LampPost(this.x, this.y);
  final double x;
  final double y;
}

class Pigeon {
  Pigeon(this.x, this.y);
  double x;
  double y;
  double vx = 0;
  double vy = 0;
  double startled = 0;
}

class Orb {
  Orb(this.x, this.y, this.type);
  double x;
  double y;
  final int type; // 0 xp, 1 ration
}

class Shot {
  Shot(this.x, this.y, this.dx, this.dy, this.weapon);
  double x;
  double y;
  final double dx;
  final double dy;
  final String weapon;
  double life = 1;
}

class Shockwave {
  Shockwave(this.x, this.y);
  final double x;
  final double y;
  double life = 2.4;
}

class DamageNumber {
  DamageNumber(this.x, this.y, this.amount, this.color);
  double x;
  double y;
  final int amount;
  final Color color;
  double life = 1;
}
