import 'package:flutter/material.dart';

import '../models.dart';

const kBrand = Color(0xFF0F766E);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kBrand,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF7F8F8),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Color(0xFFF7F8F8),
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

Color kindColor(ListingKind k) => switch (k) {
  ListingKind.offer => const Color(0xFF0F766E),
  ListingKind.request => const Color(0xFFB45309),
  ListingKind.agency => const Color(0xFF1D4ED8),
};

IconData kindIcon(ListingKind k) => switch (k) {
  ListingKind.offer => Icons.home_work_outlined,
  ListingKind.request => Icons.person_search_outlined,
  ListingKind.agency => Icons.apartment_outlined,
};
