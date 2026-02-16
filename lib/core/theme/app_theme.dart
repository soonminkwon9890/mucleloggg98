import 'package:flutter/material.dart';

class AppTheme {
  // 1. Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white, // 밝은 배경
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    cardTheme: CardThemeData(
      color: Colors.white, // [표준] 밝은 카드
      elevation: 1, // [유지] 은은한 그림자
      shadowColor: Colors.black.withValues(alpha: 0.05), // [유지]
      surfaceTintColor: Colors.transparent, // [유지] 틴트 제거
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
    ),
    extensions: const <ThemeExtension<dynamic>>[
      AppCardTheme(
        onCardColor: Colors.black, // [표준] 밝은 카드 위 검은 글씨
        subTextColor: Colors.grey,
      ),
    ],
  );

  // 2. Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.black, // 어두운 배경
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1C1C1E), // [표준] 어두운 카드
      elevation: 1, // [유지]
      shadowColor: Colors.black.withValues(alpha: 0.05), // [유지]
      surfaceTintColor: Colors.transparent, // [유지]
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Color(0xFF1C1C1E),
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
    ),
    extensions: const <ThemeExtension<dynamic>>[
      AppCardTheme(
        onCardColor: Colors.white, // [표준] 어두운 카드 위 흰 글씨
        subTextColor: Colors.grey,
      ),
    ],
  );
}

// 3. Theme Extension Definition
@immutable
class AppCardTheme extends ThemeExtension<AppCardTheme> {
  final Color onCardColor;
  final Color subTextColor;

  const AppCardTheme({
    required this.onCardColor,
    required this.subTextColor,
  });

  @override
  AppCardTheme copyWith({Color? onCardColor, Color? subTextColor}) {
    return AppCardTheme(
      onCardColor: onCardColor ?? this.onCardColor,
      subTextColor: subTextColor ?? this.subTextColor,
    );
  }

  @override
  AppCardTheme lerp(ThemeExtension<AppCardTheme>? other, double t) {
    if (other is! AppCardTheme) return this;
    return AppCardTheme(
      onCardColor: Color.lerp(onCardColor, other.onCardColor, t)!,
      subTextColor: Color.lerp(subTextColor, other.subTextColor, t)!,
    );
  }
}
