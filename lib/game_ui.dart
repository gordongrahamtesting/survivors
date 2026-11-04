import 'package:flutter/material.dart';

import 'game_content.dart';

class Hud extends StatelessWidget {
  const Hud({
    super.key,
    required this.level,
    required this.xp,
    required this.xpToLevel,
    required this.hp,
    required this.kills,
    required this.elapsed,
  });
  final int level, xp, xpToLevel, hp, kills;
  final double elapsed;
  @override
  Widget build(BuildContext context) {
    final displayedHp = hp.clamp(0, 100);
    final minutes = (elapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (elapsed % 60).floor().toString().padLeft(2, '0');
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 15),
        decoration: BoxDecoration(
          color: const Color(0xff121820).withValues(alpha: .92),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: .07)),
          ),
        ),
        child: Row(
          children: [
            const Text(
              'GRAMPA',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: Color(0xffffc15b),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'SURVIVORS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white70,
              ),
            ),
            const Spacer(),
            _Stat(label: 'RUN TIME', value: '$minutes:$seconds'),
            const SizedBox(width: 30),
            _Stat(label: 'KILLS', value: '$kills'),
            const SizedBox(width: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'LEVEL $level  •  XP $xp / $xpToLevel',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                SizedBox(
                  width: 190,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (xp / xpToLevel).clamp(0.0, 1.0),
                      minHeight: 6,
                      color: const Color(0xffe6a84d),
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VITALITY  $displayedHp%',
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: displayedHp / 100,
                      minHeight: 6,
                      color: const Color(0xff7fc87f),
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          letterSpacing: 1.2,
          color: Colors.white38,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ],
  );
}

class WeaponBar extends StatelessWidget {
  const WeaponBar({
    super.key,
    required this.title,
    required this.weapons,
    required this.cooldowns,
    required this.levels,
    this.bottom = 13,
    required this.side,
  });
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
    return GameContent.find(weapon)?.icon ?? '⌁';
  }

  String _label(String weapon) {
    return GameContent.find(weapon)?.label ?? 'ITEM';
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
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
                color: Colors.white38,
              ),
            ),
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
                    border: Border.all(
                      color: color.withValues(alpha: .75),
                      width: 1.5,
                    ),
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
                      Text(
                        _icon(weapon),
                        style: TextStyle(
                          fontSize: 28,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: Text(
                          _label(weapon),
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: .7,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 1,
                        child: Text(
                          '${levels[weapon] ?? 1}/5',
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.white70,
                          ),
                        ),
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

class PauseBanner extends StatelessWidget {
  const PauseBanner({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xff1a222b),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 34, vertical: 22),
        child: Text(
          'PAUSED',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: Color(0xffffc15b),
          ),
        ),
      ),
    ),
  );
}

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    super.key,
    required this.level,
    required this.kills,
    required this.elapsed,
    required this.won,
    required this.onRestart,
  });
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
                Text(
                  won ? '20 MINUTES!' : 'GAME OVER',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: won
                        ? const Color(0xffffc15b)
                        : const Color(0xffef8b79),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'RUN TIME ${_formatDuration(elapsed)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'LEVEL $level  •  KILLS $kills',
                  style: const TextStyle(
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
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

class UpgradeOverlay extends StatelessWidget {
  const UpgradeOverlay({
    super.key,
    required this.level,
    required this.levels,
    required this.choices,
    required this.onChoose,
  });
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
        return _card(
          '◉',
          weapon,
          'Fires a candy projectile at a nearby enemy.',
          const Color(0xffd98f4a),
        );
      case 'Upgraded Cane':
        return _card(
          '⌁',
          weapon,
          'Replaces the cane with a longer, wider melee swing.',
          const Color(0xff77a8bd),
        );
      case 'Noisy Grandkid':
        return _card(
          '↻',
          weapon,
          'Launches a slow, loud projectile at a nearby enemy.',
          const Color(0xffcf6c68),
        );
      case 'Canvas Trolleys':
        return _card(
          '▣',
          weapon,
          'Five carts orbit Grampa and damage enemies on contact; upgrades spin faster.',
          const Color(0xff91ad83),
        );
      case 'Thermos Tea':
        return _card(
          '☕',
          weapon,
          'Targets an enemy and damages enemies in a large hot splash.',
          const Color(0xffc88c62),
        );
      case 'Reading Glasses':
        return _card(
          '⌕',
          weapon,
          'A passive upgrade; currently has no additional combat effect.',
          const Color(0xff9ca8d4),
        );
      case 'Pocket Radio':
        return _card(
          '♫',
          weapon,
          'Stuns every enemy around Grampa for 2.5 seconds.',
          const Color(0xffd4b35e),
        );
      case 'Comfy Slippers':
        return _card(
          '靴',
          weapon,
          'Increases Grampa’s movement speed.',
          const Color(0xffb98d68),
        );
      case 'Helping Hand':
        return _card(
          '☝',
          weapon,
          'Increases the pickup radius for XP and rations.',
          const Color(0xffd5a56a),
        );
      case 'Lucky Sweater':
        return _card(
          '♥',
          weapon,
          'Increases maximum health and reduces enemy contact damage.',
          const Color(0xffd27d88),
        );
      case 'Silver Watch':
        return _card(
          '◷',
          weapon,
          'Reduces weapon cooldowns by 10% per rank.',
          const Color(0xffb5c5d6),
        );
      case 'Bingo Blaster':
        return _card(
          '✦',
          weapon,
          'Fires five random-direction bingo balls.',
          const Color(0xffd8b15f),
        );
      case 'Garden Hose':
        return _card(
          '≈',
          weapon,
          'Fires eight water shots clockwise in all directions.',
          const Color(0xff70b6c4),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _card(String icon, String weapon, String copy, Color color) {
    final isPassive =
        weapon == 'Comfy Slippers' ||
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
    child: Container(
      color: const Color(0xff0c1015).withValues(alpha: .86),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1020),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'A LITTLE SOMETHING EXTRA',
                style: TextStyle(
                  color: Color(0xffffc15b),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'LEVEL $level',
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: choices.map(_choiceCard).toList(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({
    required this.icon,
    required this.title,
    required this.copy,
    required this.color,
    required this.onTap,
  });
  final String icon, title, copy;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 210,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 182,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xff18212a),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: .55)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: TextStyle(fontSize: 28, color: color)),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              copy,
              maxLines: 4,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white60,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'SELECT  →',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: color,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
