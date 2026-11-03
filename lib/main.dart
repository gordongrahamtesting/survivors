import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const GrandpaSurvivors());

class GrandpaSurvivors extends StatelessWidget {
  const GrandpaSurvivors({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grampa Survivors',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff11151b),
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffe6a84d),
          brightness: Brightness.dark,
        ),
      ),
      home: const GameScreen(),
    );
  }

}

class MyApp extends GrandpaSurvivors {
  const MyApp({super.key});
}

class Enemy {
  Enemy(this.x, this.y, this.kind, this.maxHp);
  double x;
  double y;
  final int kind;
  final double maxHp;
  late double hp = maxHp;
  double stunned = 0;
  double teaDamageCooldown = 0;
  double contactCooldown = 0;
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
  double _px = .5, _py = .5, _elapsed = 0, _spawnClock = 0, _swingTimer = 0, _swingAngle = 0, _hitTimer = 0, _trolleyAngle = 0, _trolleyActive = 0, _trolleyCooldown = 0, _teaSplashTimer = 0, _teaSplashX = 0, _teaSplashY = 0;
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

  int _xpToLevel() => 70 + _level * 35;

  double _enemyHealth() => 38 + math.max(0, _level - 1) * 8 + _elapsed / 60 * 6;

  int _scaledDamage(int baseDamage) =>
      (baseDamage * (1 + math.max(0, _level - 1) * .015)).round();

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 10; i++) {
      final a = _random.nextDouble() * math.pi * 2;
      final r = .18 + _random.nextDouble() * .34;
      _enemies.add(Enemy(.5 + math.cos(a) * r, .5 + math.sin(a) * r, i % 4, _enemyHealth()));
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
        .45,
        1.5 - _elapsed / 100 - difficultyLevel * .06,
      );
      if (_spawnClock > spawnInterval) {
        _spawnClock = 0;
        final maxEnemies = 15 + math.max(0, _level - 5) * 4;
        final spawns = math.min(1 + difficultyLevel ~/ 4, maxEnemies - _enemies.length);
        for (var spawn = 0; spawn < spawns; spawn++) {
          final edge = _random.nextInt(4);
          final x = edge == 0 ? .03 : edge == 1 ? .97 : _random.nextDouble();
          final y = edge == 2 ? .12 : edge == 3 ? .9 : .12 + _random.nextDouble() * .78;
          _enemies.add(Enemy(x, y, _random.nextInt(4), _enemyHealth()));
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
          final enemySpeed = .0018 + difficultyLevel * .00012;
          enemy.x += dx / d * enemySpeed;
          enemy.y += dy / d * enemySpeed;
        } else if (enemy.contactCooldown == 0) {
          final contactDamage = math.max(1, 3 + difficultyLevel ~/ 3 - (_weaponLevels['Lucky Sweater'] ?? 0));
          _hp = math.max(0, _hp - contactDamage);
          _hitTimer = .2;
          enemy.contactCooldown = .8;
          if (_hp == 0) _gameOver = true;
        }
      }
      if (_teaSplashTimer > 0) {
        for (final enemy in _enemies) {
          final splashDistance = math.sqrt((enemy.x - _teaSplashX) * (enemy.x - _teaSplashX) + (enemy.y - _teaSplashY) * (enemy.y - _teaSplashY));
          if (splashDistance < .16 && enemy.hp > 0 && enemy.teaDamageCooldown == 0) {
            enemy.hp -= _scaledDamage(12);
            enemy.teaDamageCooldown = .35;
            _damageNumbers.add(DamageNumber(enemy.x, enemy.y, 12, const Color(0xffffc58a)));
            if (enemy.hp <= 0) {
              _orbs.add(Orb(enemy.x, enemy.y, _random.nextDouble() < .06 ? 1 : 0));
              _kills++;
              _xp += 4;
            }
          }
        }
      }
      for (final weapon in _ownedWeapons) {
        final cooldownRate = 1 + (_weaponLevels['Silver Watch'] ?? 0) * .1;
        final cooldown = math.max(0.0, (_weaponCooldowns[weapon] ?? 0) - .032 * cooldownRate).toDouble();
        _weaponCooldowns[weapon] = cooldown;
        if (weapon == 'Canvas Trolleys' ||
            weapon == 'Comfy Slippers' ||
            weapon == 'Reading Glasses' ||
            weapon == 'Helping Hand' ||
            weapon == 'Lucky Sweater' ||
            weapon == 'Silver Watch') {
          continue;
        }
        Enemy? target;
        var best = 99.0;
        for (final enemy in _enemies) {
          if (enemy.hp <= 0) continue;
          final d = math.sqrt((_px - enemy.x) * (_px - enemy.x) + (_py - enemy.y) * (_py - enemy.y));
          if (d < best) { best = d; target = enemy; }
        }
        if (weapon == 'Pocket Radio' && _enemies.isNotEmpty) {
          target = _enemies[_random.nextInt(_enemies.length)];
          best = math.sqrt((target.x - _px) * (target.x - _px) + (target.y - _py) * (target.y - _py));
        }
        final isCane = weapon == 'Cane of Consequences' || weapon == 'Upgraded Cane';
        if (cooldown > 0) continue;
        final range = isCane
            ? (weapon == 'Upgraded Cane' ? .15 : .12)
            : weapon == 'Pocket Radio'
                ? 2.0
                : 1.2;
        final canFire = target != null && (!isCane || best < range);
        if (canFire) {
          if (isCane) {
            final reach = weapon == 'Upgraded Cane' ? .15 : .12;
            _swingTimer = .22;
            _swingAngle = math.atan2(target.y - _py, target.x - _px);
            for (final enemy in _enemies) {
              final distance = math.sqrt((enemy.x - _px) * (enemy.x - _px) + (enemy.y - _py) * (enemy.y - _py));
              if (distance < reach) {
                final damage = weapon == 'Upgraded Cane' ? 26 : 20;
                enemy.hp -= _scaledDamage(damage);
                _damageNumbers.add(DamageNumber(enemy.x, enemy.y, damage, const Color(0xffc7e2ee)));
                if (enemy.hp <= 0) {
                  _orbs.add(Orb(enemy.x, enemy.y, _random.nextDouble() < .06 ? 1 : 0));
                  _kills++;
                  _xp += 4;
                }
              }
            }
          } else {
            final dx = target.x - _px, dy = target.y - _py, d = math.sqrt(dx * dx + dy * dy);
            if (weapon == 'Thermos Tea') {
              _teaSplashX = target.x;
              _teaSplashY = target.y;
              _teaSplashTimer = 2.8;
              for (final enemy in _enemies) {
                final splashDistance = math.sqrt((enemy.x - target.x) * (enemy.x - target.x) + (enemy.y - target.y) * (enemy.y - target.y));
                if (splashDistance < .16 && enemy.hp > 0) {
                  enemy.hp -= _scaledDamage(35);
                  enemy.teaDamageCooldown = .35;
                  _damageNumbers.add(DamageNumber(enemy.x, enemy.y, 35, const Color(0xffffc58a)));
                  if (enemy.hp <= 0) {
                    _orbs.add(Orb(enemy.x, enemy.y, _random.nextDouble() < .06 ? 1 : 0));
                    _kills++;
                    _xp += 4;
                  }
                }
              }
            } else {
              final shotSpeed = weapon == 'Noisy Grandkid' ? .006 : weapon == 'Bingo Blaster' ? .01 : .012;
              _shots.add(Shot(_px, _py, dx / d * shotSpeed, dy / d * shotSpeed, weapon));
            }
          }
          _weaponCooldowns[weapon] = weapon == 'Noisy Grandkid'
              ? 5
              : weapon == 'Thermos Tea'
                  ? 10
                  : weapon == 'Pocket Radio'
                      ? 5
                      : isCane
                              ? 3
                          : weapon == 'Bingo Blaster'
                              ? 3.5
                          : weapon == 'Garden Hose'
                              ? 4.5
                          : 2;
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
            final distance = math.sqrt((enemy.x - trolleyX) * (enemy.x - trolleyX) + (enemy.y - trolleyY) * (enemy.y - trolleyY));
            if (distance < .035 && enemy.hp > 0) {
              enemy.hp -= _scaledDamage(20 + trolleyRank * 5);
              _trolleyHitTimers[i] = .24;
              _damageNumbers.add(DamageNumber(enemy.x, enemy.y, 20 + trolleyRank * 5, const Color(0xffc6e8ae)));
              if (enemy.hp <= 0) {
                _orbs.add(Orb(enemy.x, enemy.y, _random.nextDouble() < .06 ? 1 : 0));
                _kills++;
                _xp += 4;
              }
              break;
            }
          }
        }
      }
      for (final shot in _shots) {
        shot.x += shot.dx; shot.y += shot.dy; shot.life -= .018;
        for (final enemy in _enemies) {
          final hitDistance = math.sqrt((shot.x - enemy.x) * (shot.x - enemy.x) + (shot.y - enemy.y) * (shot.y - enemy.y));
          final hitRadius = shot.weapon == 'Thermos Tea' ? .06 : .035;
          if (hitDistance < hitRadius && enemy.hp > 0) {
            final damage = _scaledDamage(shot.weapon == 'Pocket Radio'
                ? 15
                : shot.weapon == 'Noisy Grandkid'
                    ? 40
                    : shot.weapon == 'Thermos Tea'
                        ? 35
                        : shot.weapon == 'Garden Hose'
                            ? 24
                            : shot.weapon == 'Bingo Blaster'
                                ? 22
                                : 30);
            if (shot.weapon == 'Pocket Radio') {
              _shockwaves.add(Shockwave(shot.x, shot.y));
              final pushX = enemy.x - shot.x;
              final pushY = enemy.y - shot.y;
              final pushDistance = math.max(.001, math.sqrt(pushX * pushX + pushY * pushY));
              enemy.x = (enemy.x + pushX / pushDistance * .12).clamp(.04, .96);
              enemy.y = (enemy.y + pushY / pushDistance * .12).clamp(.12, .94);
              enemy.stunned = 1.8;
              enemy.hp -= damage;
            } else {
              enemy.hp -= damage;
            }
            final damageColor = shot.weapon == 'Pocket Radio'
                ? const Color(0xffffe29a)
                : shot.weapon == 'Noisy Grandkid'
                ? const Color(0xffffa2a0)
                : shot.weapon == 'Thermos Tea'
                    ? const Color(0xffffc58a)
                    : const Color(0xffffd477);
            _damageNumbers.add(DamageNumber(enemy.x, enemy.y, damage, damageColor));
            if (enemy.hp <= 0) {
              _orbs.add(Orb(enemy.x, enemy.y, _random.nextDouble() < .06 ? 1 : 0));
              _kills++;
              _xp += 4;
            }
            shot.life = 0;
          }
        }
      }
      _shots.removeWhere((s) => s.life <= 0 || s.x < 0 || s.x > 1 || s.y < .1 || s.y > 1);
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
          _xp += orb.type == 0 ? 2 : 0;
          if (orb.type == 1) _hp = math.min(_maxHp(), _hp + 14);
          orb.x = -1;
        }
      }
      _orbs.removeWhere((o) => o.x < 0);
      final xpToLevel = _xpToLevel();
      if (_xp >= xpToLevel) {
        _level++;
        _xp -= xpToLevel;
        final upgradePool = [
          'Werthers Originals',
          'Noisy Grandkid',
          'Canvas Trolleys',
          'Thermos Tea',
          'Reading Glasses',
          'Pocket Radio',
          'Comfy Slippers',
          'Helping Hand',
          'Bingo Blaster',
          'Garden Hose',
          'Lucky Sweater',
          'Silver Watch',
        ];
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
        final previousCooldown = _weaponCooldowns.remove('Cane of Consequences') ?? 0;
        _weaponCooldowns[name] = previousCooldown;
      } else {
        if (!_ownedWeapons.contains(name)) _ownedWeapons.add(name);
        _weaponLevels[name] = math.min(5, (_weaponLevels[name] ?? 0) + 1);
        _weaponCooldowns[name] = 0;
        if (name == 'Canvas Trolleys' && _trolleyActive == 0 && _trolleyCooldown == 0) {
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
        _enemies.add(Enemy(.5 + math.cos(a) * r, .5 + math.sin(a) * r, i % 4, _enemyHealth()));
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
              if (event.logicalKey == LogicalKeyboardKey.space && event is KeyDownEvent) {
                setState(() => _paused = !_paused);
              }
            },
            child: LayoutBuilder(builder: (context, constraints) {
              return Stack(
                children: [
                  CustomPaint(
                    painter: ArenaPainter(_px, _py, _enemies, _orbs, _shots, _damageNumbers, _shockwaves, _trolleyHitTimers, _swingTimer, _swingAngle, _hitTimer, _trolleyAngle, _ownedWeapons.contains('Canvas Trolleys') && _trolleyActive > 0, _teaSplashTimer, _teaSplashX, _teaSplashY, _weapon),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                  _Hud(level: _level, xp: _xp, xpToLevel: _xpToLevel(), hp: _hp, kills: _kills, elapsed: _elapsed),
                  _WeaponBar(
                    title: 'WEAPONS',
                    weapons: _ownedWeapons.where((weapon) => weapon != 'Cane of Consequences' && weapon != 'Upgraded Cane' && weapon != 'Comfy Slippers' && weapon != 'Reading Glasses' && weapon != 'Helping Hand' && weapon != 'Lucky Sweater' && weapon != 'Silver Watch').toList(),
                    cooldowns: {
                      ..._weaponCooldowns,
                      'Canvas Trolleys': _trolleyCooldown,
                    },
                    levels: _weaponLevels,
                    side: Alignment.centerRight,
                  ),
                  _WeaponBar(
                    title: 'PASSIVES',
                    weapons: _ownedWeapons.where((weapon) => weapon == 'Comfy Slippers' || weapon == 'Reading Glasses' || weapon == 'Helping Hand' || weapon == 'Lucky Sweater' || weapon == 'Silver Watch').toList(),
                    cooldowns: const {},
                    levels: _weaponLevels,
                    bottom: 88,
                    side: Alignment.centerLeft,
                  ),
                  Positioned(
                    bottom: 20, left: 22,
                    child: Text('WASD / ARROWS  MOVE   •   SPACE  PAUSE',
                      style: TextStyle(color: Colors.white.withValues(alpha: .52), fontSize: 11, letterSpacing: 1.1)),
                  ),
                  if (_paused) const _PauseBanner(),
                  if (_levelUp) _UpgradeOverlay(level: _level, levels: _weaponLevels, choices: _upgradeChoices, onChoose: _chooseUpgrade),
                  if (_gameOver) _GameOverOverlay(level: _level, kills: _kills, elapsed: _elapsed, won: false, onRestart: _restartGame),
                  if (_won) _GameOverOverlay(level: _level, kills: _kills, elapsed: _elapsed, won: true, onRestart: _restartGame),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.level, required this.xp, required this.xpToLevel, required this.hp, required this.kills, required this.elapsed});
  final int level, xp, xpToLevel, hp, kills;
  final double elapsed;
  @override
  Widget build(BuildContext context) {
    final minutes = (elapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (elapsed % 60).floor().toString().padLeft(2, '0');
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 15),
        decoration: BoxDecoration(color: const Color(0xff121820).withValues(alpha: .92), border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: .07)))),
        child: Row(children: [
          const Text('GRAMPA', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3, color: Color(0xffffc15b))),
          const SizedBox(width: 8),
          const Text('SURVIVORS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white70)),
          const Spacer(),
          _Stat(label: 'RUN TIME', value: '$minutes:$seconds'),
          const SizedBox(width: 30),
          _Stat(label: 'KILLS', value: '$kills'),
          const SizedBox(width: 30),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('LEVEL $level  •  XP $xp / $xpToLevel', style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 7),
            SizedBox(width: 190, child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (xp / xpToLevel).clamp(0.0, 1.0), minHeight: 6, color: const Color(0xffe6a84d), backgroundColor: Colors.white12))),
          ]),
          const SizedBox(width: 24),
          SizedBox(width: 100, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('VITALITY  $hp%', style: const TextStyle(fontSize: 10, letterSpacing: 1, color: Colors.white70)),
            const SizedBox(height: 7),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: hp / 100, minHeight: 6, color: const Color(0xff7fc87f), backgroundColor: Colors.white12)),
          ])),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
    Text(label, style: const TextStyle(fontSize: 9, letterSpacing: 1.2, color: Colors.white38)),
    const SizedBox(height: 3),
    Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
  ]);
}

class _WeaponBar extends StatelessWidget {
  const _WeaponBar({required this.title, required this.weapons, required this.cooldowns, required this.levels, this.bottom = 13, required this.side});
  final String title;
  final List<String> weapons;
  final Map<String, double> cooldowns;
  final Map<String, int> levels;
  final double bottom;
  final Alignment side;

  double _duration(String weapon) {
    if (weapon == 'Canvas Trolleys') return 10;
    return 2;
  }

  String _icon(String weapon) {
    if (weapon == 'Noisy Grandkid') return '↻';
    if (weapon == 'Werthers Originals') return '●';
    if (weapon == 'Canvas Trolleys') return '▣';
    if (weapon == 'Comfy Slippers') return '靴';
    if (weapon == 'Thermos Tea') return '☕';
    if (weapon == 'Reading Glasses') return '⌕';
    if (weapon == 'Helping Hand') return '☝';
    if (weapon == 'Lucky Sweater') return '♥';
    if (weapon == 'Silver Watch') return '◷';
    if (weapon == 'Bingo Blaster') return '✦';
    if (weapon == 'Garden Hose') return '≈';
    if (weapon == 'Pocket Radio') return '♫';
    return '⌁';
  }

  String _label(String weapon) {
    if (weapon == 'Cane of Consequences') return 'CANE';
    if (weapon == 'Upgraded Cane') return 'CANE +';
    if (weapon == 'Werthers Originals') return 'CANDY';
    if (weapon == 'Canvas Trolleys') return 'CARTS';
    if (weapon == 'Comfy Slippers') return 'SPEED';
    if (weapon == 'Thermos Tea') return 'TEA';
    if (weapon == 'Reading Glasses') return 'FOCUS';
    if (weapon == 'Helping Hand') return 'MAGNET';
    if (weapon == 'Lucky Sweater') return 'SWEATER';
    if (weapon == 'Silver Watch') return 'WATCH';
    if (weapon == 'Bingo Blaster') return 'BINGO';
    if (weapon == 'Garden Hose') return 'HOSE';
    if (weapon == 'Pocket Radio') return 'RADIO';
    if (weapon == 'Noisy Grandkid') return 'BABY';
    return 'ITEM';
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: side,
            child: Text(title, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.4, color: Colors.white38)),
          ),
          const SizedBox(height: 3),
          Align(
            alignment: side,
            child: Row(
            mainAxisSize: MainAxisSize.min,
            children: weapons.map((weapon) {
          final cooldown = cooldowns[weapon] ?? 0;
          final progress = (cooldown / _duration(weapon)).clamp(0.0, 1.0);
          final color = weapon == 'Noisy Grandkid'
              ? const Color(0xffcf6c68)
              : weapon == 'Werthers Originals'
                  ? const Color(0xffe6a84d)
                  : weapon == 'Canvas Trolleys'
                      ? const Color(0xff91ad83)
                      : weapon == 'Comfy Slippers'
                          ? const Color(0xffb98d68)
                          : weapon == 'Thermos Tea'
                              ? const Color(0xffc88c62)
                              : weapon == 'Reading Glasses'
                                  ? const Color(0xff9ca8d4)
                                  : weapon == 'Pocket Radio'
                                      ? const Color(0xffd4b35e)
                                      : const Color(0xff8cb8c8);
          return Container(
            width: 68,
            height: 68,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xff111820).withValues(alpha: .94),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: .75), width: 1.5),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  color: Colors.white.withValues(alpha: .82),
                  backgroundColor: Colors.white.withValues(alpha: .08),
                ),
                Text(_icon(weapon), style: TextStyle(fontSize: 28, color: color, fontWeight: FontWeight.bold)),
                Positioned(
                  bottom: 0,
                  child: Text(
                    _label(weapon),
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: .7, color: Colors.white70),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 1,
                  child: Text('${levels[weapon] ?? 1}/5', style: const TextStyle(fontSize: 8, color: Colors.white70)),
                ),
              ],
            ),
          );
          }).toList(),
          ),
          ),
        ],
      ),
    );
  }
}

class _PauseBanner extends StatelessWidget {
  const _PauseBanner();
  @override
  Widget build(BuildContext context) => const Center(child: DecoratedBox(
    decoration: BoxDecoration(color: Color(0xff1a222b), borderRadius: BorderRadius.all(Radius.circular(12))),
    child: Padding(padding: EdgeInsets.symmetric(horizontal: 34, vertical: 22), child: Text('PAUSED', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 4, color: Color(0xffffc15b)))),
  ));
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({required this.level, required this.kills, required this.elapsed, required this.won, required this.onRestart});
  final int level, kills;
  final double elapsed;
  final bool won;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Container(
      color: const Color(0xff0c1015).withValues(alpha: .9),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xff1a222b),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xffd96d62), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(won ? '20 MINUTES!' : 'GAME OVER', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4, color: won ? const Color(0xffffc15b) : const Color(0xffef8b79))),
                const SizedBox(height: 12),
                Text('RUN TIME ${_formatDuration(elapsed)}', style: const TextStyle(color: Colors.white70, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text('LEVEL $level  •  KILLS $kills', style: const TextStyle(color: Colors.white70, letterSpacing: 1)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onRestart,
                  child: const Text('TRY AGAIN'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

String _formatDuration(double elapsed) {
  final minutes = (elapsed ~/ 60).toString().padLeft(2, '0');
  final seconds = (elapsed % 60).floor().toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _UpgradeOverlay extends StatelessWidget {
  const _UpgradeOverlay({required this.level, required this.levels, required this.choices, required this.onChoose});
  final int level;
  final Map<String, int> levels;
  final List<String> choices;
  final ValueChanged<String> onChoose;

  String _title(String weapon) {
    final rank = levels[weapon] ?? 0;
    return rank == 0 ? weapon : 'Improved $weapon';
  }

  String _rank(String weapon) => '${levels[weapon] ?? 0}/5';

  Widget _choiceCard(String weapon) {
    switch (weapon) {
      case 'Werthers Originals':
        return _card('◉', weapon, 'Hard candy. Harder hits.', const Color(0xffd98f4a));
      case 'Upgraded Cane':
        return _card('⌁', weapon, 'The old reliable. Wider bonk radius.', const Color(0xff77a8bd));
      case 'Noisy Grandkid':
        return _card('↻', weapon, 'A baby-shaped boomerang of pure volume.', const Color(0xffcf6c68));
      case 'Canvas Trolleys':
        return _card('▣', weapon, 'Five carts orbit Grampa and bonk on contact.', const Color(0xff91ad83));
      case 'Thermos Tea':
        return _card('☕', weapon, 'A hot splash that reaches farther.', const Color(0xffc88c62));
      case 'Reading Glasses':
        return _card('⌕', weapon, 'Focuses the next attack for a bigger hit.', const Color(0xff9ca8d4));
      case 'Pocket Radio':
        return _card('♫', weapon, 'A shockwave of oldies knocks teens back.', const Color(0xffd4b35e));
      case 'Comfy Slippers':
        return _card('靴', weapon, 'A little extra pep in every step.', const Color(0xffb98d68));
      case 'Helping Hand':
        return _card('☝', weapon, 'Pulls nearby XP and rations in from farther away.', const Color(0xffd5a56a));
      case 'Lucky Sweater':
        return _card('♥', weapon, 'Adds health and softens enemy contact damage.', const Color(0xffd27d88));
      case 'Silver Watch':
        return _card('◷', weapon, 'Shortens every weapon cooldown a little.', const Color(0xffb5c5d6));
      case 'Bingo Blaster':
        return _card('✦', weapon, 'A slow, heavy bingo ball with a satisfying thump.', const Color(0xffd8b15f));
      case 'Garden Hose':
        return _card('≈', weapon, 'Steady water shots keep the crowd at bay.', const Color(0xff70b6c4));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _card(String icon, String weapon, String copy, Color color) {
    final isPassive = weapon == 'Comfy Slippers' ||
        weapon == 'Reading Glasses' ||
        weapon == 'Helping Hand' ||
        weapon == 'Lucky Sweater' ||
        weapon == 'Silver Watch';
    return _Card(
      icon: icon,
      title: _title(weapon),
      copy: '${isPassive ? 'PASSIVE' : 'WEAPON'}  •  $copy  ${_rank(weapon)}',
      color: color,
      onTap: () => onChoose(weapon),
    );
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Container(color: const Color(0xff0c1015).withValues(alpha: .86), child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 840),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('A LITTLE SOMETHING EXTRA', style: TextStyle(color: Color(0xffffc15b), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 3)),
        const SizedBox(height: 8),
        Text('LEVEL $level', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 28),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: choices.map(_choiceCard).toList(),
        ),
      ]),
    ))),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.icon, required this.title, required this.copy, required this.color, required this.onTap});
  final String icon, title, copy;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(width: 180, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: Container(
    height: 142, padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: const Color(0xff18212a), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: .55))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(icon, style: TextStyle(fontSize: 28, color: color)),
      const Spacer(),
      Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 5),
      Text(copy, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.white60, height: 1.2)),
      const SizedBox(height: 7),
      Text('SELECT  →', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: color)),
    ]),
  )));
}

class ArenaPainter extends CustomPainter {
  ArenaPainter(this.px, this.py, this.enemies, this.orbs, this.shots, this.damageNumbers, this.shockwaves, this.trolleyHitTimers, this.swingTimer, this.swingAngle, this.hitTimer, this.trolleyAngle, this.hasTrolleys, this.teaSplashTimer, this.teaSplashX, this.teaSplashY, this.weapon);
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
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xff182229);
    canvas.drawRect(Offset.zero & size, bg);
    final area = Rect.fromLTWH(0, 76, size.width, size.height - 76);
    final grid = Paint()..color = const Color(0xff25343a)..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 76), Offset(x, size.height), grid);
    }
    for (var y = 76.0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    Offset at(double x, double y) => Offset(size.width * x, size.height * y);
    canvas.drawRect(area, Paint()..color = const Color(0xff1a282f).withValues(alpha: .32));
    for (final orb in orbs) {
      final p = at(orb.x, orb.y);
      if (orb.type == 1) {
        final glow = Paint()..color = const Color(0xffd8b15f).withValues(alpha: .18);
        canvas.drawCircle(p, 14, glow);
        final pack = Paint()..color = const Color(0xff6f7650);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 18, height: 13), const Radius.circular(2)),
          pack,
        );
        canvas.drawLine(p + const Offset(-7, -4), p + const Offset(7, -4), Paint()..color = const Color(0xffaeb27a)..strokeWidth = 2);
        canvas.drawLine(p + const Offset(0, -6), p + const Offset(0, 6), Paint()..color = const Color(0xff4d5538)..strokeWidth = 2);
        canvas.drawRect(Rect.fromCenter(center: p + const Offset(0, 1), width: 6, height: 6), Paint()..color = const Color(0xffd8b15f));
        canvas.drawLine(p + const Offset(-2, 1), p + const Offset(2, 1), Paint()..color = const Color(0xff6f7650)..strokeWidth = 1);
        canvas.drawLine(p + const Offset(0, -1), p + const Offset(0, 3), Paint()..color = const Color(0xff6f7650)..strokeWidth = 1);
      } else {
        final xpPaint = Paint()..color = const Color(0xff82c6c6);
        canvas.drawCircle(p, 5, xpPaint);
        canvas.drawCircle(p, 9, Paint()..color = xpPaint.color.withValues(alpha: .16));
      }
    }
    for (final shot in shots) {
      final p = at(shot.x, shot.y);
      final phase = .72 + math.sin((1 - shot.life) * math.pi * 8).abs() * .28;
      if (shot.weapon == 'Noisy Grandkid') {
        final babyGlow = Paint()..color = const Color(0xffff9a9a).withValues(alpha: .12 * phase);
        canvas.drawCircle(p, 16 + phase * 3, babyGlow);
        canvas.drawCircle(p + const Offset(0, -6), 7 + phase, Paint()..color = const Color(0xffffc4a8).withValues(alpha: phase));
        canvas.drawOval(Rect.fromCenter(center: p + const Offset(0, 5), width: 13 + phase * 2, height: 14 + phase * 2), Paint()..color = const Color(0xffcf6c68).withValues(alpha: phase));
        canvas.drawLine(p + const Offset(-7, 2), p + const Offset(-11, 8), Paint()..color = const Color(0xffffc4a8).withValues(alpha: phase)..strokeWidth = 3);
        canvas.drawLine(p + const Offset(7, 2), p + const Offset(11, 8), Paint()..color = const Color(0xffffc4a8).withValues(alpha: phase)..strokeWidth = 3);
        canvas.drawCircle(p + const Offset(-3, -7), 1.5, Paint()..color = Colors.black87);
        canvas.drawCircle(p + const Offset(3, -7), 1.5, Paint()..color = Colors.black87);
        canvas.drawCircle(p + const Offset(0, -3), 2.5, Paint()..color = const Color(0xfff1d8d0).withValues(alpha: phase));
      } else if (shot.weapon == 'Thermos Tea') {
        final tea = Paint()..color = const Color(0xffc88c62).withValues(alpha: phase);
        canvas.drawCircle(p, 18 + phase * 4, Paint()..color = const Color(0xffffc58a).withValues(alpha: .12 * phase));
        canvas.drawOval(Rect.fromCenter(center: p, width: 12 + phase * 2, height: 16 + phase * 2), tea);
        canvas.drawArc(Rect.fromCenter(center: p + const Offset(7, 0), width: 9, height: 10), -math.pi / 2, math.pi, false, tea..style = PaintingStyle.stroke..strokeWidth = 3);
        canvas.drawArc(Rect.fromCenter(center: p + const Offset(-3, -11), width: 8, height: 14), math.pi, math.pi, false, Paint()..color = Colors.white.withValues(alpha: .5 * phase)..style = PaintingStyle.stroke..strokeWidth = 2);
      } else if (shot.weapon == 'Pocket Radio') {
        final pulse = Paint()
          ..color = const Color(0xffd4b35e).withValues(alpha: .65 * phase)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 18, height: 13), const Radius.circular(3)), Paint()..color = const Color(0xff6d5f3f).withValues(alpha: phase));
        canvas.drawLine(p + const Offset(-6, -6), p + const Offset(-10, -14), pulse);
        canvas.drawArc(Rect.fromCircle(center: p, radius: 15 + phase * 5), -1.1, 2.2, false, pulse);
      } else if (shot.weapon == 'Reading Glasses') {
        final beam = Paint()
          ..color = const Color(0xff9ca8d4).withValues(alpha: .6 * phase)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        canvas.drawCircle(p, 7, beam);
        canvas.drawCircle(p, 14 + phase * 3, Paint()..color = const Color(0xff9ca8d4).withValues(alpha: .12 * phase));
      } else {
        final candy = Paint()..color = const Color(0xffffd477).withValues(alpha: phase);
        canvas.drawCircle(p, 7 + phase * 2, candy);
        canvas.drawCircle(p, 13 + phase * 3, Paint()..color = const Color(0xffffd477).withValues(alpha: .12 * phase));
        canvas.drawLine(p + const Offset(-10, 0), p + const Offset(-5, 0), Paint()..color = const Color(0xffd98f4a).withValues(alpha: phase)..strokeWidth = 3);
        canvas.drawLine(p + const Offset(5, 0), p + const Offset(10, 0), Paint()..color = const Color(0xffd98f4a).withValues(alpha: phase)..strokeWidth = 3);
      }
    }
    for (final shockwave in shockwaves) {
      final progress = 1 - shockwave.life / 2.4;
      final center = at(shockwave.x, shockwave.y);
      final radius = 18 + progress * 105;
      final alpha = (shockwave.life / 2.4).clamp(0.0, 1.0);
      final pulse = Paint()
        ..color = const Color(0xffd4b35e).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7;
      canvas.drawCircle(center, radius, pulse);
      canvas.drawCircle(center, radius * .72, Paint()..color = const Color(0xffffe29a).withValues(alpha: .16 * alpha));
      canvas.drawCircle(center, radius * .45, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = const Color(0xfffff0b3).withValues(alpha: .55 * alpha));
    }
    for (final e in enemies) {
      final p = at(e.x, e.y);
      final stunned = e.stunned > 0;
      final color = e.kind == 0
          ? const Color(0xffd08b52) // e-scooter teen
          : e.kind == 1
              ? const Color(0xff84aa86) // vape cloud teen
              : e.kind == 2
                  ? const Color(0xff77768c) // goth
                  : const Color(0xffb86a65); // hoodie kid
      canvas.drawCircle(p, stunned ? 20 : 16, Paint()..color = (stunned ? const Color(0xffffe29a) : color).withValues(alpha: stunned ? .24 : .16));
      final body = Paint()..color = stunned ? color.withValues(alpha: .7) : color;
      if (e.kind == 0) {
        canvas.drawOval(Rect.fromCenter(center: p + const Offset(0, 6), width: 17, height: 22), body);
        canvas.drawLine(p + const Offset(-7, 7), p + const Offset(-11, 17), Paint()..color = color..strokeWidth = 4);
        canvas.drawLine(p + const Offset(7, 7), p + const Offset(11, 17), Paint()..color = color..strokeWidth = 4);
      } else if (e.kind == 1) {
        final hoodie = Path()
          ..moveTo(p.dx - 12, p.dy + 15)
          ..lineTo(p.dx - 9, p.dy - 1)
          ..quadraticBezierTo(p.dx, p.dy - 8, p.dx + 9, p.dy - 1)
          ..lineTo(p.dx + 12, p.dy + 15)
          ..close();
        canvas.drawPath(hoodie, body);
        canvas.drawLine(p + const Offset(-8, 3), p + const Offset(-14, 11), Paint()..color = color..strokeWidth = 4);
        canvas.drawLine(p + const Offset(8, 3), p + const Offset(14, 11), Paint()..color = color..strokeWidth = 4);
      } else if (e.kind == 2) {
        final coat = Path()
          ..moveTo(p.dx - 9, p.dy - 2)
          ..lineTo(p.dx - 14, p.dy + 17)
          ..lineTo(p.dx + 14, p.dy + 17)
          ..lineTo(p.dx + 9, p.dy - 2)
          ..close();
        canvas.drawPath(coat, body);
        canvas.drawLine(p + const Offset(-8, 4), p + const Offset(-14, 15), Paint()..color = color..strokeWidth = 4);
        canvas.drawLine(p + const Offset(8, 4), p + const Offset(14, 15), Paint()..color = color..strokeWidth = 4);
        canvas.drawLine(p + const Offset(0, 5), p + const Offset(0, 17), Paint()..color = const Color(0xff171721)..strokeWidth = 2);
      } else {
        final hoodie = Path()
          ..moveTo(p.dx - 13, p.dy + 16)
          ..lineTo(p.dx - 11, p.dy - 3)
          ..quadraticBezierTo(p.dx, p.dy - 12, p.dx + 11, p.dy - 3)
          ..lineTo(p.dx + 13, p.dy + 16)
          ..close();
        canvas.drawPath(hoodie, body);
        canvas.drawLine(p + const Offset(-8, 4), p + const Offset(-15, 13), Paint()..color = color..strokeWidth = 5);
        canvas.drawLine(p + const Offset(8, 4), p + const Offset(15, 13), Paint()..color = color..strokeWidth = 5);
      }
      canvas.drawCircle(p + const Offset(0, -6), 9, Paint()..color = e.kind == 2 ? const Color(0xff24232d) : const Color(0xffd99d72));
      final face = Paint()..color = e.kind == 2 ? const Color(0xff16161c) : Colors.white70;
      canvas.drawCircle(p + const Offset(-3, -2), 2, face);
      canvas.drawCircle(p + const Offset(3, -2), 2, face);
      if (stunned) {
        canvas.drawArc(Rect.fromCircle(center: p + const Offset(0, -22), radius: 8), math.pi, math.pi, false, Paint()..color = const Color(0xffffe29a)..strokeWidth = 2..style = PaintingStyle.stroke);
        canvas.drawCircle(p + const Offset(-8, -24), 2, Paint()..color = const Color(0xffffe29a));
        canvas.drawCircle(p + const Offset(8, -24), 2, Paint()..color = const Color(0xffffe29a));
      }
      if (e.kind == 0) {
        final wheel = Paint()..color = const Color(0xff2e3439)..style = PaintingStyle.stroke..strokeWidth = 2;
        canvas.drawCircle(p + const Offset(-11, 18), 4, wheel);
        canvas.drawCircle(p + const Offset(11, 18), 4, wheel);
        canvas.drawLine(p + const Offset(-11, 18), p + const Offset(10, 13), wheel);
        canvas.drawLine(p + const Offset(0, 0), p + const Offset(10, 13), wheel);
        canvas.drawLine(p + const Offset(5, 5), p + const Offset(13, 5), wheel);
      } else if (e.kind == 1) {
        final cloud = Paint()..color = const Color(0xffc7d7c2).withValues(alpha: .65);
        canvas.drawCircle(p + const Offset(12, -12), 4, cloud);
        canvas.drawCircle(p + const Offset(17, -17), 3, cloud);
        canvas.drawCircle(p + const Offset(20, -22), 2, cloud);
      } else if (e.kind == 2) {
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
      } else {
        final hood = Paint()..color = const Color(0xff8e454e).withValues(alpha: .9);
        canvas.drawArc(Rect.fromCircle(center: p + const Offset(0, -5), radius: 11), math.pi, math.pi, false, hood..style = PaintingStyle.stroke..strokeWidth = 4);
      }
    }
    final g = at(px, py);
    if (teaSplashTimer > 0) {
      final splashProgress = 1 - teaSplashTimer / 2.8;
      final splashAlpha = math.min(1.0, .35 + teaSplashTimer / 2.8);
      final splash = at(teaSplashX, teaSplashY);
      final radius = 30 + splashProgress * 78;
      canvas.drawCircle(splash, radius, Paint()..color = const Color(0xffffc58a).withValues(alpha: .12 * splashAlpha));
      canvas.drawCircle(splash, radius, Paint()..style = PaintingStyle.stroke..strokeWidth = 6..color = const Color(0xffc88c62).withValues(alpha: .9 * splashAlpha));
      canvas.drawCircle(splash, radius * .72, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = const Color(0xffffd09a).withValues(alpha: .6 * splashAlpha));
      canvas.drawOval(Rect.fromCenter(center: splash, width: 34, height: 24), Paint()..color = const Color(0xff9a5d38).withValues(alpha: .9 * splashAlpha));
      for (var i = 0; i < 4; i++) {
        final steamX = splash.dx - 18 + i * 12;
        final steamY = splash.dy - 26 - math.sin((splashProgress * 8) + i) * 8;
        canvas.drawArc(Rect.fromCenter(center: Offset(steamX, steamY), width: 12, height: 28), math.pi, math.pi, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = Colors.white.withValues(alpha: .55 * splashAlpha));
      }
    }
    for (final damage in damageNumbers) {
      final alpha = math.min(1.0, damage.life * 3);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '-${damage.amount}',
          style: TextStyle(color: damage.color.withValues(alpha: alpha), fontSize: 15, fontWeight: FontWeight.w900),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, at(damage.x, damage.y) - Offset(textPainter.width / 2, 20));
    }
    if (hasTrolleys) {
      for (var i = 0; i < 5; i++) {
        final angle = trolleyAngle + i * math.pi * 2 / 5;
        final trolley = at(px + math.cos(angle) * (.105 + i * 0.0), py + math.sin(angle) * (.105 + i * 0.0));
        final hitPulse = trolleyHitTimers[i] > 0 ? math.sin((trolleyHitTimers[i] / .24) * math.pi) : 0;
        final opacity = 0.72 + hitPulse * .28;
        final bag = Paint()..color = const Color(0xff2876a2).withValues(alpha: opacity);
        canvas.drawCircle(trolley, 15 + hitPulse * 5, Paint()..color = const Color(0xff9ed0e5).withValues(alpha: .12 + hitPulse * .2));
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: trolley + const Offset(0, -2), width: 22, height: 20), const Radius.circular(4)), bag);
        canvas.drawLine(trolley + const Offset(-8, -12), trolley + const Offset(8, -12), Paint()..color = const Color(0xffc7d7d4).withValues(alpha: opacity)..strokeWidth = 2);
        canvas.drawLine(trolley + const Offset(-8, -12), trolley + const Offset(-10, -3), Paint()..color = const Color(0xffc7d7d4).withValues(alpha: opacity)..strokeWidth = 2);
        canvas.drawLine(trolley + const Offset(8, -12), trolley + const Offset(10, -3), Paint()..color = const Color(0xffc7d7d4).withValues(alpha: opacity)..strokeWidth = 2);
        canvas.drawLine(trolley + const Offset(-7, 3), trolley + const Offset(7, 3), Paint()..color = const Color(0xff8fc0d1).withValues(alpha: opacity)..strokeWidth = 1);
        canvas.drawCircle(trolley + const Offset(-8, 11), 4, Paint()..color = const Color(0xff3d464b).withValues(alpha: opacity));
        canvas.drawCircle(trolley + const Offset(8, 11), 4, Paint()..color = const Color(0xff3d464b).withValues(alpha: opacity));
      }
    }
    final hitPulse = hitTimer > 0 ? math.sin((hitTimer / .2) * math.pi) : 0;
    canvas.drawCircle(g, 27 + hitPulse * 8, Paint()..color = (hitPulse > 0 ? const Color(0xffef6a62) : const Color(0xffe6a84d)).withValues(alpha: .12 + hitPulse * .18));
    if (hitPulse > 0) {
      canvas.drawCircle(g, 26 + hitPulse * 5, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = const Color(0xffef6a62).withValues(alpha: hitPulse * .8));
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: g + const Offset(0, 9), width: 25, height: 27), const Radius.circular(7)),
      Paint()..color = const Color(0xffb98d68),
    );
    canvas.drawLine(g + const Offset(-8, 20), g + const Offset(-11, 28), Paint()..color = const Color(0xff292b30)..strokeWidth = 5);
    canvas.drawLine(g + const Offset(8, 20), g + const Offset(11, 28), Paint()..color = const Color(0xff292b30)..strokeWidth = 5);
    canvas.drawCircle(g, 18 + hitPulse * 2, Paint()..color = const Color(0xffd9a06a));
    canvas.drawCircle(g + const Offset(0, -14), 13 + hitPulse * 1.5, Paint()..color = const Color(0xffe5b789));
    final cap = Paint()..color = const Color(0xff62605a);
    canvas.drawOval(Rect.fromCenter(center: g + const Offset(0, -27), width: 29, height: 9), cap);
    canvas.drawArc(Rect.fromCenter(center: g + const Offset(0, -26), width: 22, height: 13), math.pi, math.pi, false, cap..style = PaintingStyle.fill);
    canvas.drawCircle(g + const Offset(-5, -17), 2, Paint()..color = Colors.black87);
    canvas.drawCircle(g + const Offset(5, -17), 2, Paint()..color = Colors.black87);
    final cane = Paint()..color = const Color(0xff9f6b49)..strokeWidth = 4..strokeCap = StrokeCap.round;
    final caneAngle = swingTimer > 0 ? swingAngle - math.atan2(21, 13) : 0.0;
    canvas.save();
    canvas.translate(g.dx, g.dy);
    canvas.rotate(caneAngle);
    canvas.drawLine(const Offset(14, 3), const Offset(27, 24), cane);
    canvas.drawArc(Rect.fromCircle(center: const Offset(12, 0), radius: 6), -.3, 2.4, false, cane);
    canvas.restore();
    if (swingTimer > 0) {
      final reach = weapon == 'Upgraded Cane' ? 45.0 : 35.0;
      final swing = Paint()
        ..color = const Color(0xffc28a5c)
        ..style = PaintingStyle.stroke
        ..strokeWidth = weapon == 'Upgraded Cane' ? 7 : 5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: g, radius: reach), swingAngle - 1.15, 2.3, false, swing);
      if (weapon == 'Upgraded Cane') {
        canvas.drawArc(Rect.fromCircle(center: g, radius: reach), swingAngle + math.pi - 1.15, 2.3, false, swing);
      }
    }
    canvas.drawCircle(g + const Offset(-5, -17), 2, Paint()..color = Colors.black87);
    canvas.drawCircle(g + const Offset(5, -17), 2, Paint()..color = Colors.black87);
    canvas.drawRect(area, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.white.withValues(alpha: .08));
  }
  @override
  bool shouldRepaint(covariant ArenaPainter oldDelegate) => true;
}
