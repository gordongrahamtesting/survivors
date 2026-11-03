enum ContentKind { weapon, passive, enemy }
enum WeaponAttack { cane, candy, noisy, radio, tea, bingo, hose, trolley }

class ContentDefinition {
  const ContentDefinition({
    required this.name,
    required this.kind,
    required this.icon,
    required this.label,
  });

  final String name;
  final ContentKind kind;
  final String icon;
  final String label;
}

class WeaponDefinition extends ContentDefinition {
  const WeaponDefinition({
    required super.name,
    required super.icon,
    required super.label,
    required this.attack,
    required this.cooldown,
    this.range = 1.2,
    this.damage = 30,
    this.projectileSpeed = .012,
    this.hitRadius = .035,
  }) : super(kind: ContentKind.weapon);

  final WeaponAttack attack;
  final double cooldown;
  final double range;
  final int damage;
  final double projectileSpeed;
  final double hitRadius;
}

class PassiveDefinition extends ContentDefinition {
  const PassiveDefinition({
    required super.name,
    required super.icon,
    required super.label,
  }) : super(kind: ContentKind.passive);
}

class GameContent {
  static const definitions = <ContentDefinition>[
    WeaponDefinition(name: 'Cane of Consequences', icon: '⌁', label: 'CANE', attack: WeaponAttack.cane, cooldown: 3, range: .12, damage: 20),
    WeaponDefinition(name: 'Upgraded Cane', icon: '⌁', label: 'CANE +', attack: WeaponAttack.cane, cooldown: 3, range: .15, damage: 26),
    WeaponDefinition(name: 'Werthers Originals', icon: '●', label: 'CANDY', attack: WeaponAttack.candy, cooldown: 2),
    WeaponDefinition(name: 'Noisy Grandkid', icon: '↻', label: 'BABY', attack: WeaponAttack.noisy, cooldown: 5, damage: 40, projectileSpeed: .006),
    WeaponDefinition(name: 'Canvas Trolleys', icon: '▣', label: 'CARTS', attack: WeaponAttack.trolley, cooldown: 10),
    WeaponDefinition(name: 'Thermos Tea', icon: '☕', label: 'TEA', attack: WeaponAttack.tea, cooldown: 10, damage: 35),
    WeaponDefinition(name: 'Pocket Radio', icon: '♫', label: 'RADIO', attack: WeaponAttack.radio, cooldown: 5, range: 2, damage: 15, hitRadius: .06),
    WeaponDefinition(name: 'Bingo Blaster', icon: '✦', label: 'BINGO', attack: WeaponAttack.bingo, cooldown: 3.5, damage: 22),
    WeaponDefinition(name: 'Garden Hose', icon: '≈', label: 'HOSE', attack: WeaponAttack.hose, cooldown: 4.5, damage: 24, hitRadius: .05),
    PassiveDefinition(name: 'Comfy Slippers', icon: '靴', label: 'SPEED'),
    PassiveDefinition(name: 'Reading Glasses', icon: '⌕', label: 'FOCUS'),
    PassiveDefinition(name: 'Helping Hand', icon: '☝', label: 'MAGNET'),
    PassiveDefinition(name: 'Lucky Sweater', icon: '♥', label: 'SWEATER'),
    PassiveDefinition(name: 'Silver Watch', icon: '◷', label: 'WATCH'),
  ];

  static List<String> get upgradeNames => definitions
      .where((definition) => definition.name != 'Cane of Consequences' &&
          definition.name != 'Upgraded Cane')
      .map((definition) => definition.name)
      .toList();

  static ContentDefinition? find(String name) {
    for (final definition in definitions) {
      if (definition.name == name) return definition;
    }
    return null;
  }

  static WeaponDefinition weapon(String name) =>
      find(name) as WeaponDefinition;

  static bool isPassive(String name) =>
      find(name)?.kind == ContentKind.passive;
}
