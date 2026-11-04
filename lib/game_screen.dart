import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final _orbs = <Orb>[];
  final _shots = <Shot>[];
  Timer? _timer;
  double _px = .5,
      _py = .5,
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
  int _xp = 0, _level = 1, _kills = 0, _hp = 86;
  bool _paused = false, _levelUp = false, _gameOver = false, _won = false;
  final _upgradeChoices = <String>[];
  String _weapon = 'Cane of Consequences';
  final _ownedWeapons = <String>['Cane of Consequences'];
  final _weaponLevels = <String, int>{'Cane of Consequences': 1};
  final _weaponCooldowns = <String, double>{'Cane of Consequences': 0};
  final _trolleyHitTimers = <double>[0, 0, 0, 0, 0];
  final _damageNumbers = <DamageNumber>[];
  final _shockwaves = <Shockwave>[];

  int _maxHp() => 86 + (_weaponLevels['Lucky Sweater'] ?? 0) * 8;

  int _xpToLevel() => 52 + _level * 25;

  double _enemyHealth() =>
      18 + math.max(0, _level - 1) * 10 + _elapsed / 60 * 8;

  Enemy _newEnemy(double x, double y, EnemyType type) {
    final angle = math.atan2(.5 - y, .5 - x) + (_random.nextDouble() - .5) * .9;
    final trajectoryOnly = _random.nextDouble() < .58;
    return Enemy(
      x,
      y,
      type,
      _enemyHealth(),
      vx: math.cos(angle),
      vy: math.sin(angle),
      trajectoryOnly: trajectoryOnly,
    );
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
        _newEnemy(
          .5 + math.cos(a) * r,
          .5 + math.sin(a) * r,
          EnemyType.values[i % 4],
        ),
      );
    }
    _timer = Timer.periodic(const Duration(milliseconds: 32), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  void _tick() {
    if (_paused || _levelUp || _gameOver || _won) return;
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
      _trolleyAngle = (_trolleyAngle + .025) % (math.pi * 2);
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
      if (_keys.contains(LogicalKeyboardKey.keyW) ||
          _keys.contains(LogicalKeyboardKey.arrowUp)) {
        _py -= speed;
      }
      if (_keys.contains(LogicalKeyboardKey.keyS) ||
          _keys.contains(LogicalKeyboardKey.arrowDown)) {
        _py += speed;
      }
      if (_keys.contains(LogicalKeyboardKey.keyA) ||
          _keys.contains(LogicalKeyboardKey.arrowLeft)) {
        _px -= speed;
      }
      if (_keys.contains(LogicalKeyboardKey.keyD) ||
          _keys.contains(LogicalKeyboardKey.arrowRight)) {
        _px += speed;
      }
      _px = _px.clamp(.08, .92);
      _py = _py.clamp(.12, .9);

      final difficultyLevel = math.max(0, _level - 1);
      final spawnInterval = math.max(
        .38,
        1.15 - _elapsed / 100 - difficultyLevel * .05,
      );
      if (_spawnClock > spawnInterval) {
        _spawnClock = 0;
        final maxEnemies = 22 + difficultyLevel * 3;
        final spawns = math.min(
          1 + difficultyLevel ~/ 3,
          maxEnemies - _enemies.length,
        );
        for (var spawn = 0; spawn < spawns; spawn++) {
          final edge = _random.nextInt(4);
          final x = edge == 0
              ? .03
              : edge == 1
              ? .97
              : _random.nextDouble();
          final y = edge == 2
              ? .12
              : edge == 3
              ? .9
              : .12 + _random.nextDouble() * .78;
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
          final enemySpeed = .00145 + difficultyLevel * .00008;
          if (enemy.trajectoryOnly && d > .28) {
            enemy.x += enemy.vx * enemySpeed;
            enemy.y += enemy.vy * enemySpeed;
          } else {
            enemy.trajectoryOnly = false;
            enemy.x += dx / d * enemySpeed;
            enemy.y += dy / d * enemySpeed;
          }
          enemy.x = enemy.x.clamp(.02, .98);
          enemy.y = enemy.y.clamp(.1, .95);
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
          if (splashDistance < .16 &&
              enemy.hp > 0 &&
              enemy.teaDamageCooldown == 0) {
            enemy.hp -= _scaledDamage(12);
            enemy.teaDamageCooldown = .35;
            _damageNumbers.add(
              DamageNumber(enemy.x, enemy.y, 12, const Color(0xffffc58a)),
            );
            if (enemy.hp <= 0) {
              _orbs.add(
                Orb(enemy.x, enemy.y, _random.nextDouble() < .06 ? 1 : 0),
              );
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
        if (weaponDefinition.attack == WeaponAttack.radio && target != null) {
          final liveEnemies = _enemies.where((enemy) => enemy.hp > 0).toList();
          target = liveEnemies[_random.nextInt(liveEnemies.length)];
          best = math.sqrt(
            (target.x - _px) * (target.x - _px) +
                (target.y - _py) * (target.y - _py),
          );
        }
        final isCane = weaponDefinition.attack == WeaponAttack.cane;
        final isHose = weaponDefinition.attack == WeaponAttack.hose;
        if (cooldown > 0) continue;
        final range = weaponDefinition.range;
        final canFire = isHose || (target != null && (!isCane || best < range));
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
                  _orbs.add(
                    Orb(enemy.x, enemy.y, _random.nextDouble() < .06 ? 1 : 0),
                  );
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
                if (splashDistance < .16 && enemy.hp > 0) {
                  enemy.hp -= _scaledDamage(35);
                  enemy.teaDamageCooldown = .35;
                  _damageNumbers.add(
                    DamageNumber(enemy.x, enemy.y, 35, const Color(0xffffc58a)),
                  );
                  if (enemy.hp <= 0) {
                    _orbs.add(
                      Orb(enemy.x, enemy.y, _random.nextDouble() < .06 ? 1 : 0),
                    );
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
                _orbs.add(
                  Orb(enemy.x, enemy.y, _random.nextDouble() < .06 ? 1 : 0),
                );
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
              enemy.x = (enemy.x + pushX / pushDistance * .12).clamp(.04, .96);
              enemy.y = (enemy.y + pushY / pushDistance * .12).clamp(.12, .94);
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
              _orbs.add(
                Orb(enemy.x, enemy.y, _random.nextDouble() < .06 ? 1 : 0),
              );
              _kills++;
              _xp += 5;
            }
            shot.life = 0;
          }
        }
      }
      _shots.removeWhere(
        (s) => s.life <= 0 || s.x < 0 || s.x > 1 || s.y < .1 || s.y > 1,
      );
      _enemies.removeWhere((e) => e.hp <= 0);
      for (final orb in _orbs) {
        var dx = _px - orb.x;
        var dy = _py - orb.y;
        var distance = math.sqrt(dx * dx + dy * dy);
        final helpingHandRank = _weaponLevels['Helping Hand'] ?? 0;
        final magnetRadius = .12 + helpingHandRank * .025;
        if (distance < magnetRadius && distance > .055) {
          orb.x += dx / distance * .008;
          orb.y += dy / distance * .008;
          dx = _px - orb.x;
          dy = _py - orb.y;
          distance = math.sqrt(dx * dx + dy * dy);
        }
        if (distance < .055) {
          _xp += orb.type == 0 ? 3 : 0;
          if (orb.type == 1) _hp = math.min(_maxHp(), _hp + 14);
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
      _px = .5;
      _py = .5;
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
          _newEnemy(
            .5 + math.cos(a) * r,
            .5 + math.sin(a) * r,
            EnemyType.values[i % 4],
          ),
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
              if (event.logicalKey == LogicalKeyboardKey.space &&
                  event is KeyDownEvent) {
                setState(() => _paused = !_paused);
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
                        'WASD / ARROWS  MOVE   •   SPACE  PAUSE',
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
