import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import '../models.dart';
import 'design.dart';

// Les couleurs de l'app viennent du design courant (voir design.dart) : ces accesseurs remplacent les anciennes constantes.
Color get kBrandDark => D.s.primaryDark;
Color get kBrand => D.s.primary;
Color get kBrandLight => D.s.primaryLight;
Color get kAccent => D.s.accent;
Color get kIndigo => D.s.tertiary;
Color get kInk => D.s.ink;
Color get kBg => D.s.bg;
Color get kSurface => D.s.surface;

LinearGradient _g(List<Color> c) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: c,
);
LinearGradient get kBrandGradient => _g(
  D.s.buttonColors.length == 1
      ? [D.s.buttonColors[0], D.s.buttonColors[0]]
      : D.s.buttonColors,
);
LinearGradient get kAccentGradient => _g(
  D.s.accentButtonColors.length == 1
      ? [D.s.accentButtonColors[0], D.s.accentButtonColors[0]]
      : D.s.accentButtonColors,
);

ThemeData buildTheme(DesignSpec d) {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: d.primary,
        brightness: d.dark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: d.primary,
        secondary: d.accent,
        tertiary: d.tertiary,
        surface: d.surface,
        onSurface: d.ink,
      );
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(d.radius),
    side: d.border > 0
        ? BorderSide(color: d.borderColor, width: d.border)
        : BorderSide.none,
  );
  OutlineInputBorder ob(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(d.radius.clamp(6, 16)),
    borderSide: BorderSide(color: c, width: w),
  );
  final line = d.dark
      ? Colors.white24
      : (d.id == DesignId.pop ? d.ink : Colors.grey.shade300);
  return ThemeData(
    useMaterial3: true,
    brightness: d.dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: d.bg,
    canvasColor: d.surface,
    textTheme:
        (d.dark ? Typography.whiteMountainView : Typography.blackMountainView)
            .apply(bodyColor: d.ink, displayColor: d.ink),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: d.ink,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: d.surface,
      margin: EdgeInsets.zero,
      shape: shape,
    ),
    dividerColor: d.dark ? Colors.white12 : null,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: d.surface,
      border: ob(line, d.id == DesignId.pop ? 2.5 : 1),
      enabledBorder: ob(line, d.id == DesignId.pop ? 2.5 : 1),
      focusedBorder: ob(d.primary, 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: d.primary,
        foregroundColor: onColor(d.primary),
        minimumSize: const Size.fromHeight(54),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(d.radius.clamp(6, 16)),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      selectedColor: d.primary.withValues(alpha: .15),
      side: BorderSide(color: line),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: d.id == DesignId.pop
          ? const Color(0xFFFFD43B)
          : d.surface,
      indicatorColor: d.id == DesignId.pop
          ? d.ink
          : d.primary.withValues(alpha: .16),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w500,
          color: d.ink,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? (d.id == DesignId.pop ? Colors.white : d.primary)
              : d.ink.withValues(alpha: .6),
        ),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}

Color kindColor(ListingKind k) => switch (k) {
  ListingKind.offer => kBrand,
  ListingKind.request => kAccent,
  ListingKind.agency => kIndigo,
};

IconData kindIcon(ListingKind k) => switch (k) {
  ListingKind.offer => Icons.home_work_outlined,
  ListingKind.request => Icons.person_search_outlined,
  ListingKind.agency => Icons.apartment_outlined,
};
