class XpUtils {
  // XP yang didapat per aksi
  static const int xpPerHabit = 10;
  static const int xpStreakBonus3 = 5;   // bonus kalau streak >= 3
  static const int xpStreakBonus7 = 15;  // bonus kalau streak >= 7
  static const int xpQuestComplete = 30; // bonus selesaikan daily quest

  // XP dibutuhkan untuk tiap level (makin tinggi makin banyak)
  static int xpForLevel(int level) {
    // Level 1→2 = 100 XP, Level 2→3 = 150, Level 3→4 = 200, dst
    return 100 + (level - 1) * 50;
  }

  // Hitung level dari total XP
  static int levelFromXp(int totalXp) {
    int level = 1;
    int xpLeft = totalXp;
    while (xpLeft >= xpForLevel(level)) {
      xpLeft -= xpForLevel(level);
      level++;
    }
    return level;
  }

  // XP tersisa menuju level berikutnya
  static int xpToNextLevel(int totalXp) {
    int level = 1;
    int xpLeft = totalXp;
    while (xpLeft >= xpForLevel(level)) {
      xpLeft -= xpForLevel(level);
      level++;
    }
    return xpForLevel(level) - xpLeft;
  }

  // Progress 0.0–1.0 untuk XP bar
  static double xpProgress(int totalXp) {
    int level = 1;
    int xpLeft = totalXp;
    while (xpLeft >= xpForLevel(level)) {
      xpLeft -= xpForLevel(level);
      level++;
    }
    return xpLeft / xpForLevel(level);
  }

  // Hitung XP reward berdasarkan streak
  static int calculateXpReward(int streakCount) {
    int bonus = 0;
    if (streakCount >= 7) bonus = xpStreakBonus7;
    else if (streakCount >= 3) bonus = xpStreakBonus3;
    return xpPerHabit + bonus;
  }

  // Label level berdasarkan angka
  static String levelTitle(int level) {
    if (level >= 20) return 'Legenda';
    if (level >= 15) return 'Master';
    if (level >= 10) return 'Ahli';
    if (level >= 5)  return 'Mahir';
    if (level >= 3)  return 'Pemula';
    return 'Baru Mulai';
  }
}
