enum CompatibilityAspect {
  lifePath,
  expression,
  soul,
  personality;

  String get storageKey {
    return switch (this) {
      CompatibilityAspect.lifePath => 'life_path',
      CompatibilityAspect.expression => 'expression',
      CompatibilityAspect.soul => 'soul',
      CompatibilityAspect.personality => 'personality',
    };
  }
}
