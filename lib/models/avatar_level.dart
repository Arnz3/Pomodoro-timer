enum AvatarLevel {
  seed,    // 0 min
  sprout,  // 25 min
  plant,   // 100 min
  tree,    // 300 min
  bigTree, // 600 min
  bloom,   // 1200 min
}

class AvatarLevelInfo {
  final AvatarLevel level;
  final String name;
  final String emoji;
  final int minMinutes; // drempel in totale focusminuten
  final String description;

  const AvatarLevelInfo({
    required this.level,
    required this.name,
    required this.emoji,
    required this.minMinutes,
    required this.description,
  });
}

const List<AvatarLevelInfo> avatarLevels = [
  AvatarLevelInfo(
    level: AvatarLevel.seed,
    name: 'Zaadje',
    emoji: '🌱',
    minMinutes: 0,
    description: 'Plant het zaadje van jouw productiviteit!',
  ),
  AvatarLevelInfo(
    level: AvatarLevel.sprout,
    name: 'Spruit',
    emoji: '🌿',
    minMinutes: 25,
    description: 'Je eerste stap — een spruit ontkiemt!',
  ),
  AvatarLevelInfo(
    level: AvatarLevel.plant,
    name: 'Plantje',
    emoji: '🪴',
    minMinutes: 100,
    description: 'Je routine groeit gestaag door.',
  ),
  AvatarLevelInfo(
    level: AvatarLevel.tree,
    name: 'Jonge Boom',
    emoji: '🌳',
    minMinutes: 300,
    description: 'Serieuze focusser — een stevige boom!',
  ),
  AvatarLevelInfo(
    level: AvatarLevel.bigTree,
    name: 'Grote Boom',
    emoji: '🌲',
    minMinutes: 600,
    description: 'Productiviteitsmeester — de boom trotseert alles.',
  ),
  AvatarLevelInfo(
    level: AvatarLevel.bloom,
    name: 'Bloem',
    emoji: '✨',
    minMinutes: 1200,
    description: 'Legendarisch! Je plant staat in volle bloei.',
  ),
];

/// Geeft het huidige avatar level terug op basis van totale focusminuten.
AvatarLevelInfo getAvatarLevelInfo(int totalFocusMinutes) {
  AvatarLevelInfo current = avatarLevels.first;
  for (final info in avatarLevels) {
    if (totalFocusMinutes >= info.minMinutes) {
      current = info;
    } else {
      break;
    }
  }
  return current;
}

/// Geeft de volgende level info terug, of null als max level bereikt.
AvatarLevelInfo? getNextLevelInfo(AvatarLevel current) {
  final currentIndex = AvatarLevel.values.indexOf(current);
  if (currentIndex < AvatarLevel.values.length - 1) {
    return avatarLevels[currentIndex + 1];
  }
  return null;
}

/// Voortgang (0.0 - 1.0) richting het volgende level.
double getProgressToNextLevel(int totalFocusMinutes) {
  final current = getAvatarLevelInfo(totalFocusMinutes);
  final next = getNextLevelInfo(current.level);
  if (next == null) return 1.0; // max level

  final range = next.minMinutes - current.minMinutes;
  final progress = totalFocusMinutes - current.minMinutes;
  return (progress / range).clamp(0.0, 1.0);
}
