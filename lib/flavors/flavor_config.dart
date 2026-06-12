enum FlavorType { free, pro }

class FlavorConfig {
  final FlavorType flavor;
  final String appName;
  final bool hasAIMatching;
  final bool hasAdvancedFilters;
  final bool hasUnlimitedProjects;
  final int maxProjects;
  final int maxMatches;

  const FlavorConfig._({
    required this.flavor,
    required this.appName,
    required this.hasAIMatching,
    required this.hasAdvancedFilters,
    required this.hasUnlimitedProjects,
    required this.maxProjects,
    required this.maxMatches,
  });

  static const FlavorConfig free = FlavorConfig._(
    flavor: FlavorType.free,
    appName: 'DevSync',
    hasAIMatching: false, // Basic matching only
    hasAdvancedFilters: false,
    hasUnlimitedProjects: false,
    maxProjects: 3,
    maxMatches: 5,
  );

  static const FlavorConfig pro = FlavorConfig._(
    flavor: FlavorType.pro,
    appName: 'DevSync Pro',
    hasAIMatching: true,
    hasAdvancedFilters: true,
    hasUnlimitedProjects: true,
    maxProjects: 999,
    maxMatches: 999,
  );

  static FlavorConfig _instance = pro; // Default to pro during development
  static FlavorConfig get instance => _instance;

  static void setFlavor(FlavorType type) {
    _instance = type == FlavorType.pro ? pro : free;
  }

  bool get isFree => flavor == FlavorType.free;
  bool get isPro => flavor == FlavorType.pro;
}
