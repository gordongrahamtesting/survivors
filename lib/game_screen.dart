import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gamepads/gamepads.dart';

import 'arena_painter.dart';
import 'game_content.dart';
import 'game_entities.dart';
import 'enemy_types.dart';
import 'game_ui.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _random = math.Random();
  final _keys = <LogicalKeyboardKey>{};
  final _focus = FocusNode();
  final _enemies = <Enemy>[];
  bool _gameStarted = false;
  
  // Gamepad stream subscription and tracking variables
  StreamSubscription<NormalizedGamepadEvent>? _gamepadSubscription;
  double _leftStickX = 0.0;
  double _leftStickY = 0.0;
  int _selectedUpgradeIndex = 0; // Tracks highlighted upgrade card on level up

  final _benches = const <ParkBench>[
    ParkBench(-1.55, -2.48, .28, .08),
    ParkBench(.85, -2.48, .28, .08),
    ParkBench(2.65, -2.48, .28, .08),
    ParkBench(-2.84, -.28, .08, .28),
    ParkBench(-1.55, -.27, .28, .08),
    ParkBench(2.65, -.27, .28, .08),
    ParkBench(3.52, .78, .28, .08),
    ParkBench(-3.52, 2.28, .28, .08),
    ParkBench(.85, 2.28, .28, .08),
    ParkBench(2.65, 2.28, .28, .08),
  ];
  final _paths = const <ParkPath>[
    ParkPath(0, -4.25, 8.5, .22),
    ParkPath(0, 4.25, 8.5, .22),
    ParkPath(-4.25, 0, .22, 8.5),
    ParkPath(4.25, 0, .22, 8.5),
    ParkPath(-2.65, 0, .2, 8.5),
    ParkPath(-.25, 0, .2, 8.5),
    ParkPath(1.55, 0, .2, 8.5),
    ParkPath(3.75, 0, .2, 8.5),
    ParkPath(0, -2.2, 8.5, .2),
    ParkPath(0, -.55, 8.5, .2),
    ParkPath(0, 1.95, 8.5, .2),
  ];
  final _picnicTables = const <PicnicTable>[
    PicnicTable(-1.25, -1.25, 0),
    PicnicTable(.45, -1.35, math.pi / 2),
    PicnicTable(2.9, 1.2, 0),
    PicnicTable(-3.55, 1.4, math.pi / 2),
  ];
  final _trees = const <ParkTree>[
    ParkTree(-3.55, -1.65, .65),
    ParkTree(-1.55, -1.55, .55),
    ParkTree(.85, -1.55, .65),
    ParkTree(2.65, -1.55, .6),
    ParkTree(4.15, -1.35, .6),
    ParkTree(-3.55, .85, .7),
    ParkTree(-1.55, .85, .6),
    ParkTree(.85, .85, .65),
    ParkTree(2.65, .85, .6),
    ParkTree(4.15, .85, .65),
    ParkTree(-3.55, 2.45, .6),
    ParkTree(-.85, 2.35, .65),
    ParkTree(1.55, 2.35, .6),
  ];
  final _hedges = const <ParkHedge>[
    ParkHedge(-2.05, -1.15, .8, .12),
    ParkHedge(2.15, 1.05, .8, .12),
    ParkHedge(-1.05, 1.35, .12, .8),
    ParkHedge(.85, -1.35, .12, .8),
    ParkHedge(-3.55, -1.15, .8, .12),
    ParkHedge(3.55, 1.05, .8, .12),
  ];
  final _lampPosts = const <LampPost>[
    LampPost(-2.48, -1.1),
    LampPost(-2.48, 1.1),
    LampPost(-.08, -1.1),
    LampPost(-.08, 1.1),
    LampPost(1.42, -1.1),
    LampPost(1.42, 1.1),
    LampPost(3.62, -1.1),
    LampPost(3.62, 1.1),
    LampPost(-1.45, -2.08),
    LampPost(.65, -2.08),
    LampPost(2.65, -2.08),
    LampPost(-1.45, -.43),
    LampPost(.65, -.43),
    LampPost(2.65, -.43),
    LampPost(-1.45, 2.08),
    LampPost(.65, 2.08),
    LampPost(2.65, 2.08),
  ];
  final _pigeons = <Pigeon>[
    Pigeon(-.35, .12),
    Pigeon(.35, .18),
    Pigeon(.1, -.2),
    Pigeon(-.15, -.28),
  ];
  final _orbs = <Orb>[];
  final _shots = <Shot>[];
  Timer? _timer;
  double _px = 0,
      _py = 0,
      _elapsed = 0,
      _spawnClock = 0,
      _swingTimer = 0,
      _swingAngle = 0,
      _hitTimer = 0,
      _trolleyAngle = 0,
      _trolleyActive = 0,
      _trolleyCooldown = 0,
      _teaSplashTimer = 0,
      _teaSplashX = 0,
      _teaSplashY = 0;
  double _walkTime = 0;
  int _xp = 0, _level = 1, _kills = 0, _hp = 100;
  bool _paused = false, _levelUp = false, _gameOver = false, _won = false;
  final _upgradeChoices = <String>[];
  String _weapon = 'Cane of Consequences';
  final _ownedWeapons = <String>['Cane of Consequences'];
  final _weaponLevels = <String, int>{'Cane of Consequences': 1};
  final _weaponCooldowns = <String, double>{'Cane of Consequences': 0};
  final _trolleyHitTimers = <double>[0, 0, 0, 0, 0];
  final _damageNumbers = <DamageNumber>[];
  final _shockwaves = <Shockwave>[];

  int _maxHp() => 100 + (_weaponLevels['Lucky Sweater'] ?? 0) * 8;

  int _xpToLevel() => 52 + _level * 25;

  int _pressureStage() {
    if (_elapsed >= 19 * 60) return 4;
    if (_elapsed >= 15 * 60) return 3;
    if (_elapsed >= 9 * 60) return 2;
    if (_elapsed >= 3 * 60) return 1;
    return 0;
  }

  double _enemyHealth() =>
      18 +
      _pressureStage() * 12 +
      math.max(0, _level - 4) * 10 +
      math.max(0, _elapsed - 90) / 60 * 8;

  void _dropOrb(double x, double y) {
    final roll = _random.nextDouble();
    _orbs.add(
      Orb(
        x,
        y,
        roll < .003
            ? 2
            : roll < .006
            ? 3
            : roll < .018
            ? 1
            : 0,
      ),
    );
  }

  Enemy _newEnemy(double x, double y, EnemyType type) {
    var spawnX = x;
    var spawnY = y;
    for (
      var attempt = 0;
      attempt < 12 && _blocked(spawnX, spawnY, .04);
      attempt++
    ) {
      final angle = _random.nextDouble() * math.pi * 2;
      final distance = .18 + _random.nextDouble() * .28;
      spawnX = _px + math.cos(angle) * distance;
      spawnY = _py + math.sin(angle) * distance;
    }
    final angle =
        math.atan2(_py - spawnY, _px - spawnX) +
        (_random.nextDouble() - .5) * .9;
    final trajectoryOnly = _random.nextDouble() < .58;
    return Enemy(
      spawnX,
      spawnY,
      type,
      _enemyHealth(),
      vx: math.cos(angle),
      vy: math.sin(angle),
      trajectoryOnly: trajectoryOnly,
    );
  }

  bool _blocked(double x, double y, [double radius = .035]) {
    for (final bench in _benches) {
      if ((x - bench.x).abs() < bench.width / 2 + radius &&
          (y - bench.y).abs() < bench.height / 2 + radius) {
        return true;
      }
    }
    for (final hedge in _hedges) {
      if ((x - hedge.x).abs() < hedge.width / 2 + radius &&
          (y - hedge.y).abs() < hedge.height / 2 + radius) {
        return true;
      }
    }
    for (final tree in _trees) {
      final treeRadius = tree.size * .17;
      final dx = x - tree.x;
      final dy = y - tree.y;
      if (dx * dx + dy * dy < (treeRadius + radius) * (treeRadius + radius)) {
        return true;
      }
    }
    for (final table in _picnicTables) {
      final dx = x - table.x;
      final dy = y - table.y;
      if (dx * dx + dy * dy < (.16 + radius) * (.16 + radius)) {
        return true;
      }
    }
    return false;
  }

  void _movePlayer(double dx, double dy) {
    final nextX = _px + dx;
    final nextY = _py + dy;
    if (!_blocked(nextX, _py)) _px = nextX;
    if (!_blocked(_px, nextY)) _py = nextY;
    if (dx != 0 || dy != 0) _walkTime += .22;
    _px = _px.clamp(-4.5, 4.5);
    _py = _py.clamp(-4.5, 4.5);
  }

  void _updatePigeons() {
    for (final pigeon in _pigeons) {
      final dx = pigeon.x - _px;
      final dy = pigeon.y - _py;
      final distance = math.sqrt(dx * dx + dy * dy);
      if (distance < .28 && pigeon.startled == 0) {
        pigeon.startled = 1.8;
        final safeDistance = math.max(.001, distance);
        pigeon.vx = dx / safeDistance * .012;
        pigeon.vy = dy / safeDistance * .012;
      }
      if (pigeon.startled > 0) {
        pigeon.startled = math.max(0, pigeon.startled - .032);
        pigeon.x += pigeon.vx;
        pigeon.y += pigeon.vy;
        pigeon.vx *= .994;
        pigeon.vy *= .994;
        if (pigeon.startled == 0) {
          pigeon.x = pigeon.x.clamp(-2.4, 2.4);
          pigeon.y = pigeon.y.clamp(-2.4, 2.4);
        }
      }
    }
  }

  int _scaledDamage(int baseDamage) =>
      (baseDamage * (1 + math.max(0, _level - 1) * .015)).round();

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 10; i++) {
      final a = _random.nextDouble() * math.pi * 2;
      final r = .18 + _random.nextDouble() * .34;
      _enemies.add(
        _newEnemy(math.cos(a) * r, math.sin(a) * r, EnemyType.values[i % 4]),
      );
    }
    _timer = Timer.periodic(const Duration(milliseconds: 32), (_) => _tick());

    // Listen to normalized gamepad events for navigation, combat movement, and pause
    _gamepadSubscription = Gamepads.normalizedEvents.listen((event) {
      setState(() {
        // 1. Handle Upgrade Selection Screen
        if (_levelUp) {
          if (event.button == GamepadButton.dpadLeft && event.value != 0) {
            _selectedUpgradeIndex = (_selectedUpgradeIndex - 1).clamp(0, _upgradeChoices.length - 1);
          } else if (event.button == GamepadButton.dpadRight && event.value != 0) {
            _selectedUpgradeIndex = (_selectedUpgradeIndex + 1).clamp(0, _upgradeChoices.length - 1);
          } else if (event.axis == GamepadAxis.leftStickX) {
            if (event.value < -0.5 && _leftStickX >= -0.5) {
              _selectedUpgradeIndex = (_selectedUpgradeIndex - 1).clamp(0, _upgradeChoices.length - 1);
            } else if (event.value > 0.5 && _leftStickX <= 0.5) {
              _selectedUpgradeIndex = (_selectedUpgradeIndex + 1).clamp(0, _upgradeChoices.length - 1);
            }
            _leftStickX = event.value;
          } else if (event.button == GamepadButton.a && event.value != 0) {
            if (_upgradeChoices.isNotEmpty) {
              _chooseUpgrade(_upgradeChoices[_selectedUpgradeIndex]);
            }
          }
        } 
        // 2. Handle Normal Gameplay Inputs
        else {
          if (event.axis == GamepadAxis.leftStickX) {
            _leftStickX = event.value;
          } else if (event.axis == GamepadAxis.leftStickY) {
            _leftStickY = event.value;
          } else if (event.button == GamepadButton.dpadLeft) {
            event.value != 0 ? _keys.add(LogicalKeyboardKey.arrowLeft) : _keys.remove(LogicalKeyboardKey.arrowLeft);
          } else if (event.button == GamepadButton.dpadRight) {
            event.value != 0 ? _keys.add(LogicalKeyboardKey.arrowRight) : _keys.remove(LogicalKeyboardKey.arrowRight);
          } else if (event.button == GamepadButton.dpadUp) {
            event.value != 0 ? _keys.add(LogicalKeyboardKey.arrowUp) : _keys.remove(LogicalKeyboardKey.arrowUp);
          } else if (event.button == GamepadButton.dpadDown) {
            event.value != 0 ? _keys.add(LogicalKeyboardKey.arrowDown) : _keys.remove(LogicalKeyboardKey.arrowDown);
          }
        }

        // 3. Handle Pause with Controller (Start Button)
        if (event.button == GamepadButton.start && event.value != 0) {
          if (!_gameStarted) {
            StartScreenOverlay(
              onStart: () {
                setState(() {
                  _gameStarted = true;
                  _focus.requestFocus();
                });
              },
            );
            setState(() =>_gameStarted = true);
            _focus.requestFocus();
          } else
          if (!_gameOver && !_won && !_levelUp) {
            _paused = !_paused;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _gamepadSubscription?.cancel();
    _timer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  void _tick() {
    if (!_gameStarted || _paused || _levelUp || _gameOver || _won) return;
    setState(() {
      _elapsed += .032;
      if (_elapsed >= 20 * 60) {
        _won = true;
        return;
      }
      _spawnClock += .032;
      _swingTimer = math.max(0, _swingTimer - .032);
      _hitTimer = math.max(0, _hitTimer - .032);
      _teaSplashTimer = math.max(0, _teaSplashTimer - .032);
      final trolleySpinRank = _weaponLevels['Canvas Trolleys'] ?? 1;
      _trolleyAngle =
          (_trolleyAngle + .025 + trolleySpinRank * .004) % (math.pi * 2);
      _updatePigeons();
      if (_ownedWeapons.contains('Canvas Trolleys')) {
        if (_trolleyActive > 0) {
          _trolleyActive = math.max(0, _trolleyActive - .032);
          if (_trolleyActive == 0) _trolleyCooldown = 10;
        } else {
          _trolleyCooldown = math.max(0, _trolleyCooldown - .032);
          if (_trolleyCooldown == 0) _trolleyActive = 5;
        }
      }
      for (var i = 0; i < _trolleyHitTimers.length; i++) {
        _trolleyHitTimers[i] = math.max(0, _trolleyHitTimers[i] - .032);
      }
      for (final damage in _damageNumbers) {
        damage.life -= .032;
        damage.y -= .0015;
      }
      _damageNumbers.removeWhere((damage) => damage.life <= 0);
      for (final shockwave in _shockwaves) {
        shockwave.life -= .032;
      }
      _shockwaves.removeWhere((shockwave) => shockwave.life <= 0);
      final slipperRank = _weaponLevels['Comfy Slippers'] ?? 0;
      final speed = .0065 + slipperRank * .0007;

      // Keyboard & D-Pad Movement inputs
      if (_keys.contains(LogicalKeyboardKey.keyW) ||
          _keys.contains(LogicalKeyboardKey.arrowUp)) {
        _movePlayer(0, -speed);
      }
      if (_keys.contains(LogicalKeyboardKey.keyS) ||
          _keys.contains(LogicalKeyboardKey.arrowDown)) {
        _movePlayer(0, speed);
      }
      if (_keys.contains(LogicalKeyboardKey.keyA) ||
          _keys.contains(LogicalKeyboardKey.arrowLeft)) {
        _movePlayer(-speed, 0);
      }
      if (_keys.contains(LogicalKeyboardKey.keyD) ||
          _keys.contains(LogicalKeyboardKey.arrowRight)) {
        _movePlayer(speed, 0);
      }

      // Analog Left Stick Movement inputs with deadzone
      const double deadZone = 0.15;
      if (_leftStickX.abs() > deadZone) {
        _movePlayer(speed * _leftStickX, 0);
      }
      if (_leftStickY.abs() > deadZone) {
        _movePlayer(0, -speed * _leftStickY);
      }

      final difficultyLevel = math.max(0, _level - 1);
      final pressureStage = _pressureStage();
      final spawnInterval = math.max(
        .3,
        1.05 - _elapsed / 105 - difficultyLevel * .05 - pressureStage * .08,
      );
      if (_spawnClock > spawnInterval) {
        _spawnClock = 0;
        final maxEnemies = 58 + difficultyLevel * 5 + pressureStage * 12;
        final spawns = math.min(
          3 + difficultyLevel ~/ 2 + pressureStage * 3,
          maxEnemies - _enemies.length,
        );
        for (var spawn = 0; spawn < spawns; spawn++) {
          final angle = _random.nextDouble() * math.pi * 2;
          final distance = .9 + _random.nextDouble() * .65;
          final x = _px + math.cos(angle) * distance;
          final y = _py + math.sin(angle) * distance;
          _enemies.add(_newEnemy(x, y, EnemyType.values[_random.nextInt(4)]));
        }
      }
      const playerContactRadius = .045;
      for (final enemy in _enemies) {
        enemy.stunned = math.max(0, enemy.stunned - .032);
        enemy.teaDamageCooldown = math.max(0, enemy.teaDamageCooldown - .032);
        enemy.contactCooldown = math.max(0, enemy.contactCooldown - .032);
        if (enemy.stunned > 0) continue;
        final dx = _px - enemy.x, dy = _py - enemy.y;
        final d = math.sqrt(dx * dx + dy * dy);
        if (d > playerContactRadius) {
          final enemySpeed = .00220 + difficultyLevel * .00008;
          var nextX = enemy.x;
          var nextY = enemy.y;
          if (enemy.trajectoryOnly && d > .28) {
            nextX += enemy.vx * enemySpeed;
            nextY += enemy.vy * enemySpeed;
          } else {
            enemy.trajectoryOnly = false;
            nextX += dx / d * enemySpeed;
            nextY += dy / d * enemySpeed;
          }
          if (_blocked(nextX, nextY, .025)) {
            enemy.trajectoryOnly = false;
            final options = [
              math.Point(nextX + enemySpeed, nextY),
              math.Point(nextX - enemySpeed, nextY),
              math.Point(nextX, nextY + enemySpeed),
              math.Point(nextX, nextY - enemySpeed),
            ].where((point) => !_blocked(point.x, point.y, .025)).toList();
            options.sort(
              (a, b) => math
                  .sqrt((a.x - _px) * (a.x - _px) + (a.y - _py) * (a.y - _py))
                  .compareTo(
                    math.sqrt(
                      (b.x - _px) * (b.x - _px) + (b.y - _py) * (b.y - _py),
                    ),
                  ),
            );
            if (options.isNotEmpty) {
              nextX = options.first.x;
              nextY = options.first.y;
            }
          }
          if (!_blocked(nextX, nextY, .025)) {
            enemy.facingRight = nextX >= enemy.x;
            enemy.x = nextX;
            enemy.y = nextY;
          }
        } else if (enemy.contactCooldown == 0) {
          final contactDamage = math.max(
            1,
            3 + difficultyLevel ~/ 3 - (_weaponLevels['Lucky Sweater'] ?? 0),
          );
          _hp = math.max(0, _hp - contactDamage);
          _hitTimer = .2;
          enemy.contactCooldown = .8;
          if (_hp == 0) _gameOver = true;
        }
      }
      if (_teaSplashTimer > 0) {
        for (final enemy in _enemies) {
          final splashDistance = math.sqrt(
            (enemy.x - _teaSplashX) * (enemy.x - _teaSplashX) +
                (enemy.y - _teaSplashY) * (enemy.y - _teaSplashY),
          );
          if (splashDistance < .22 &&
              enemy.hp > 0 &&
              enemy.teaDamageCooldown == 0) {
            enemy.hp -= _scaledDamage(12);
            enemy.teaDamageCooldown = .35;
            _damageNumbers.add(
              DamageNumber(enemy.x, enemy.y, 12, const Color(0xffffc58a)),
            );
            if (enemy.hp <= 0) {
              _dropOrb(enemy.x, enemy.y);
              _kills++;
              _xp += 5;
            }
          }
        }
      }
      for (final weapon in _ownedWeapons) {
        final cooldownRate = 1 + (_weaponLevels['Silver Watch'] ?? 0) * .1;
        final cooldown = math
            .max(0.0, (_weaponCooldowns[weapon] ?? 0) - .032 * cooldownRate)
            .toDouble();
        _weaponCooldowns[weapon] = cooldown;
        final definition = GameContent.find(weapon);
        if (definition == null || definition.kind == ContentKind.passive) {
          continue;
        }
        final weaponDefinition = definition as WeaponDefinition;
        Enemy? target;
        var best = 99.0;
        for (final enemy in _enemies) {
          if (enemy.hp <= 0) continue;
          final d = math.sqrt(
            (_px - enemy.x) * (_px - enemy.x) +
                (_py - enemy.y) * (_py - enemy.y),
          );
          if (d < best) {
            best = d;
            target = enemy;
          }
        }
        final isCane = weaponDefinition.attack == WeaponAttack.cane;
        final isHose = weaponDefinition.attack == WeaponAttack.hose;
        final isRadio = weaponDefinition.attack == WeaponAttack.radio;
        final isProjectile =
            weaponDefinition.attack == WeaponAttack.candy ||
            weaponDefinition.attack == WeaponAttack.noisy;
        if (isProjectile) {
          final reserved = _shots
              .map((shot) => shot.target)
              .whereType<Enemy>()
              .toSet();
          final candidates = _enemies
              .where((enemy) => enemy.hp > 0 && !reserved.contains(enemy))
              .toList();
          if (candidates.isEmpty) {
            target = null;
          } else {
            var totalWeight = 0.0;
            final weights = <double>[];
            for (final enemy in candidates) {
              final dx = enemy.x - _px;
              final dy = enemy.y - _py;
              final distance = math.sqrt(dx * dx + dy * dy);
              final weight = 1 / (.08 + distance);
              weights.add(weight);
              totalWeight += weight;
            }
            var roll = _random.nextDouble() * totalWeight;
            for (var i = 0; i < candidates.length; i++) {
              roll -= weights[i];
              if (roll <= 0 || i == candidates.length - 1) {
                target = candidates[i];
                best = math.sqrt(
                  (target.x - _px) * (target.x - _px) +
                      (target.y - _py) * (target.y - _py),
                );
                break;
              }
            }
          }
        }
        if (cooldown > 0) continue;
        final range = weaponDefinition.range;
        final canFire =
            isHose || isRadio || (target != null && (!isCane || best < range));
        if (canFire) {
          final firingTarget = target;
          if (isCane) {
            if (firingTarget == null) continue;
            final reach = weaponDefinition.range;
            _swingTimer = .22;
            _swingAngle = math.atan2(
              firingTarget.y - _py,
              firingTarget.x - _px,
            );
            for (final enemy in _enemies) {
              final distance = math.sqrt(
                (enemy.x - _px) * (enemy.x - _px) +
                    (enemy.y - _py) * (enemy.y - _py),
              );
              if (distance < reach) {
                final damage = weaponDefinition.damage;
                enemy.hp -= _scaledDamage(damage);
                _damageNumbers.add(
                  DamageNumber(
                    enemy.x,
                    enemy.y,
                    damage,
                    const Color(0xffc7e2ee),
                  ),
                );
                if (enemy.hp <= 0) {
                  _dropOrb(enemy.x, enemy.y);
                  _kills++;
                  _xp += 5;
                }
              }
            }
          } else if (isHose) {
            for (var direction = 0; direction < 8; direction++) {
              final angle = -math.pi / 2 + direction * math.pi / 4;
              _shots.add(
                Shot(
                  _px,
                  _py,
                  math.cos(angle) * weaponDefinition.projectileSpeed,
                  math.sin(angle) * weaponDefinition.projectileSpeed,
                  weapon,
                ),
              );
            }
          } else if (isRadio) {
            _shockwaves.add(Shockwave(_px, _py));
            for (final enemy in _enemies) {
              if (enemy.hp <= 0) continue;
              enemy.stunned = 2.5;
              enemy.hp -= _scaledDamage(weaponDefinition.damage);
              _damageNumbers.add(
                DamageNumber(
                  enemy.x,
                  enemy.y,
                  weaponDefinition.damage,
                  const Color(0xffffe29a),
                ),
              );
              if (enemy.hp <= 0) {
                _dropOrb(enemy.x, enemy.y);
                _kills++;
                _xp += 5;
              }
            }
          } else {
            if (firingTarget == null) continue;
            final dx = firingTarget.x - _px,
                dy = firingTarget.y - _py,
                d = math.sqrt(dx * dx + dy * dy);
            if (weaponDefinition.attack == WeaponAttack.tea) {
              _teaSplashX = firingTarget.x;
              _teaSplashY = firingTarget.y;
              _teaSplashTimer = 2.8;
              for (final enemy in _enemies) {
                final splashDistance = math.sqrt(
                  (enemy.x - firingTarget.x) * (enemy.x - firingTarget.x) +
                      (enemy.y - firingTarget.y) * (enemy.y - firingTarget.y),
                );
                if (splashDistance < .22 && enemy.hp > 0) {
                  enemy.hp -= _scaledDamage(35);
                  enemy.teaDamageCooldown = .35;
                  _damageNumbers.add(
                    DamageNumber(enemy.x, enemy.y, 35, const Color(0xffffc58a)),
                  );
                  if (enemy.hp <= 0) {
                    _dropOrb(enemy.x, enemy.y);
                    _kills++;
                    _xp += 5;
                  }
                }
              }
            } else {
              if (weaponDefinition.attack == WeaponAttack.bingo) {
                for (var ball = 0; ball < 5; ball++) {
                  final angle = _random.nextDouble() * math.pi * 2;
                  _shots.add(
                    Shot(
                      _px,
                      _py,
                      math.cos(angle) * .01,
                      math.sin(angle) * .01,
                      weapon,
                    ),
                  );
                }
              } else {
                final shotSpeed = weaponDefinition.projectileSpeed;
                _shots.add(
                  Shot(
                    _px,
                    _py,
                    dx / d * shotSpeed,
                    dy / d * shotSpeed,
                    weapon,
                    target: firingTarget,
                  ),
                );
              }
            }
          }
          _weaponCooldowns[weapon] = weaponDefinition.cooldown;
        }
      }
      if (_ownedWeapons.contains('Canvas Trolleys') && _trolleyActive > 0) {
        final trolleyRank = _weaponLevels['Canvas Trolleys'] ?? 1;
        for (var i = 0; i < 5; i++) {
          if (_trolleyHitTimers[i] > 0) continue;
          final angle = _trolleyAngle + i * math.pi * 2 / 5;
          final trolleyX = _px + math.cos(angle) * (.105 + trolleyRank * .004);
          final trolleyY = _py + math.sin(angle) * (.105 + trolleyRank * .004);
          for (final enemy in _enemies) {
            final distance = math.sqrt(
              (enemy.x - trolleyX) * (enemy.x - trolleyX) +
                  (enemy.y - trolleyY) * (enemy.y - trolleyY),
            );
            if (distance < .035 && enemy.hp > 0) {
              enemy.hp -= _scaledDamage(20 + trolleyRank * 5);
              _trolleyHitTimers[i] = .24;
              _damageNumbers.add(
                DamageNumber(
                  enemy.x,
                  enemy.y,
                  20 + trolleyRank * 5,
                  const Color(0xffc6e8ae),
                ),
              );
              if (enemy.hp <= 0) {
                _dropOrb(enemy.x, enemy.y);
                _kills++;
                _xp += 5;
              }
              break;
            }
          }
        }
      }
      for (final shot in _shots) {
        shot.x += shot.dx;
        shot.y += shot.dy;
        shot.life -= .018;
        for (final enemy in _enemies) {
          final hitDistance = math.sqrt(
            (shot.x - enemy.x) * (shot.x - enemy.x) +
                (shot.y - enemy.y) * (shot.y - enemy.y),
          );
          final shotDefinition = GameContent.weapon(shot.weapon);
          final hitRadius = shotDefinition.hitRadius;
          if (hitDistance < hitRadius && enemy.hp > 0) {
            final damage = _scaledDamage(shotDefinition.damage);
            if (shotDefinition.attack == WeaponAttack.radio) {
              _shockwaves.add(Shockwave(shot.x, shot.y));
              final pushX = enemy.x - shot.x;
              final pushY = enemy.y - shot.y;
              final pushDistance = math.max(
                .001,
                math.sqrt(pushX * pushX + pushY * pushY),
              );
              final pushedX = enemy.x + pushX / pushDistance * .12;
              final pushedY = enemy.y + pushY / pushDistance * .12;
              if (!_blocked(pushedX, pushedY, .025)) {
                enemy.x = pushedX;
                enemy.y = pushedY;
              }
              enemy.stunned = 1.8;
              enemy.hp -= damage;
            } else {
              enemy.hp -= damage;
            }
            final damageColor = shotDefinition.attack == WeaponAttack.radio
                ? const Color(0xffffe29a)
                : shotDefinition.attack == WeaponAttack.noisy
                ? const Color(0xffffa2a0)
                : shotDefinition.attack == WeaponAttack.tea
                ? const Color(0xffffc58a)
                : shotDefinition.attack == WeaponAttack.hose
                ? const Color(0xff70d0e0)
                : const Color(0xffffd477);
            _damageNumbers.add(
              DamageNumber(enemy.x, enemy.y, damage, damageColor),
            );
            if (enemy.hp <= 0) {
              _dropOrb(enemy.x, enemy.y);
              _kills++;
              _xp += 5;
            }
            shot.life = 0;
          }
        }
      }
      _shots.removeWhere(
        (s) =>
            s.life <= 0 ||
            math.sqrt((s.x - _px) * (s.x - _px) + (s.y - _py) * (s.y - _py)) >
                2.5,
      );
      _enemies.removeWhere((e) => e.hp <= 0);
      for (final orb in _orbs) {
        var dx = _px - orb.x;
        var dy = _py - orb.y;
        var distance = math.sqrt(dx * dx + dy * dy);
        final helpingHandRank = _weaponLevels['Helping Hand'] ?? 0;
        final magnetRadius = .12 + helpingHandRank * .025;
        if ((distance < magnetRadius || orb.pulledToPlayer) &&
            distance > .055) {
          final pullSpeed = orb.pulledToPlayer ? .016 : .008;
          orb.x += dx / distance * pullSpeed;
          orb.y += dy / distance * pullSpeed;
          dx = _px - orb.x;
          dy = _py - orb.y;
          distance = math.sqrt(dx * dx + dy * dy);
        }
        if (distance < .055) {
          if (orb.type == 2) {
            for (final xpOrb in _orbs) {
              if (xpOrb.type == 0 && xpOrb.x >= 0) {
                xpOrb.pulledToPlayer = true;
              }
            }
          } else if (orb.type == 3) {
            for (final enemy in _enemies) {
              if (enemy.hp > 0) enemy.hp *= .5;
            }
          } else {
            _xp += orb.type == 0 ? 3 : 0;
          }
          if (orb.type == 1) {
            _hp = math.min(_maxHp(), _hp + (_maxHp() / 4).round());
          }
          orb.x = -1;
        }
      }
      _orbs.removeWhere((o) => o.x < 0);
      final xpToLevel = _xpToLevel();
      if (_xp >= xpToLevel) {
        _level++;
        _xp -= xpToLevel;
        final upgradePool = GameContent.upgradeNames;
        if (_ownedWeapons.contains('Cane of Consequences') &&
            !_ownedWeapons.contains('Upgraded Cane')) {
          upgradePool.add('Upgraded Cane');
        }
        upgradePool.shuffle(_random);
        _upgradeChoices
          ..clear()
          ..addAll(upgradePool.take(3));
        _selectedUpgradeIndex = 0; // Reset highlighted choice on level up
        _levelUp = true;
      }
    });
  }

  void _chooseUpgrade(String name) {
    setState(() {
      _weapon = name;
      if (name == 'Upgraded Cane') {
        _ownedWeapons.remove('Cane of Consequences');
        _ownedWeapons.add(name);
        final rank = 1;
        _weaponLevels.remove('Cane of Consequences');
        _weaponLevels[name] = rank;
        final previousCooldown =
            _weaponCooldowns.remove('Cane of Consequences') ?? 0;
        _weaponCooldowns[name] = previousCooldown;
      } else {
        if (!_ownedWeapons.contains(name)) _ownedWeapons.add(name);
        _weaponLevels[name] = math.min(5, (_weaponLevels[name] ?? 0) + 1);
        _weaponCooldowns[name] = 0;
        if (name == 'Canvas Trolleys' &&
            _trolleyActive == 0 &&
            _trolleyCooldown == 0) {
          _trolleyActive = 5;
        }
      }
      _levelUp = false;
    });
    _focus.requestFocus();
  }

  void _restartGame() {
    setState(() {
      _px = 0;
      _py = 0;
      _elapsed = 0;
      _spawnClock = 0;
      _swingTimer = 0;
      _hitTimer = 0;
      _trolleyAngle = 0;
      _trolleyActive = 0;
      _trolleyCooldown = 0;
      _teaSplashTimer = 0;
      _teaSplashX = 0;
      _teaSplashY = 0;
      _xp = 0;
      _level = 1;
      _kills = 0;
      _hp = 100;
      _paused = false;
      _levelUp = false;
      _gameOver = false;
      _won = false;
      _weapon = 'Cane of Consequences';
      _ownedWeapons
        ..clear()
        ..add('Cane of Consequences');
      _weaponLevels
        ..clear()
        ..['Cane of Consequences'] = 1;
      _weaponCooldowns
        ..clear()
        ..['Cane of Consequences'] = 0;
      _upgradeChoices.clear();
      _enemies.clear();
      _orbs.clear();
      _shots.clear();
      _damageNumbers.clear();
      _shockwaves.clear();
      for (var i = 0; i < 10; i++) {
        final a = _random.nextDouble() * math.pi * 2;
        final r = .18 + _random.nextDouble() * .34;
        _enemies.add(
          _newEnemy(math.cos(a) * r, math.sin(a) * r, EnemyType.values[i % 4]),
        );
      }
    });
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180, maxHeight: 760),
          child: KeyboardListener(
            focusNode: _focus,
            autofocus: true,
            onKeyEvent: (event) {
              if (event is KeyDownEvent) _keys.add(event.logicalKey);
              if (event is KeyUpEvent) _keys.remove(event.logicalKey);
              if ((event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.enter) &&
              event is KeyDownEvent) {
                setState(() {
                  if (!_gameStarted) {
                    _gameStarted = true;
                    } else {
                      _paused = !_paused;
                    }
                  });
                }
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    CustomPaint(
                      painter: ArenaPainter(
                        _px,
                        _py,
                        _enemies,
                        _orbs,
                        _shots,
                        _damageNumbers,
                        _shockwaves,
                        _trolleyHitTimers,
                        _swingTimer,
                        _swingAngle,
                        _hitTimer,
                        _trolleyAngle,
                        _ownedWeapons.contains('Canvas Trolleys') &&
                            _trolleyActive > 0,
                        _teaSplashTimer,
                        _teaSplashX,
                        _teaSplashY,
                        _weapon,
                        _benches,
                        _trees,
                        _hedges,
                        _lampPosts,
                        _pigeons,
                        _walkTime,
                        _paths,
                        _picnicTables,
                      ),
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                    Hud(
                      level: _level,
                      xp: _xp,
                      xpToLevel: _xpToLevel(),
                      hp: _hp,
                      kills: _kills,
                      elapsed: _elapsed,
                    ),
                    WeaponBar(
                      title: 'WEAPONS',
                      weapons: _ownedWeapons
                          .where(
                            (weapon) =>
                                weapon != 'Cane of Consequences' &&
                                weapon != 'Upgraded Cane' &&
                                weapon != 'Comfy Slippers' &&
                                weapon != 'Reading Glasses' &&
                                weapon != 'Helping Hand' &&
                                weapon != 'Lucky Sweater' &&
                                weapon != 'Silver Watch',
                          )
                          .toList(),
                      cooldowns: {
                        ..._weaponCooldowns,
                        'Canvas Trolleys': _trolleyCooldown,
                      },
                      levels: _weaponLevels,
                      side: Alignment.centerRight,
                    ),
                    WeaponBar(
                      title: 'PASSIVES',
                      weapons: _ownedWeapons
                          .where(GameContent.isPassive)
                          .toList(),
                      cooldowns: const {},
                      levels: _weaponLevels,
                      bottom: 88,
                      side: Alignment.centerLeft,
                    ),
                    Positioned(
                      bottom: 20,
                      left: 22,
                      child: Text(
                        'WASD / ARROWS / GAMEPAD  MOVE   •   START  PAUSE',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .52),
                          fontSize: 11,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    if (_paused) const PauseBanner(),
                    if (_levelUp)
                      UpgradeOverlay(
                        level: _level,
                        levels: _weaponLevels,
                        choices: _upgradeChoices,
                        selectedIndex: _selectedUpgradeIndex,
                        onChoose: _chooseUpgrade,
                      ),
                    if (_gameOver)
                      GameOverOverlay(
                        level: _level,
                        kills: _kills,
                        elapsed: _elapsed,
                        won: false,
                        onRestart: _restartGame,
                      ),
                    if (_won)
                      GameOverOverlay(
                        level: _level,
                        kills: _kills,
                        elapsed: _elapsed,
                        won: true,
                        onRestart: _restartGame,
                      ),
                    if (!_gameStarted)
                      StartScreenOverlay(
                        onStart: () {
                          setState(() => _gameStarted = true);
                          _focus.requestFocus();
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}