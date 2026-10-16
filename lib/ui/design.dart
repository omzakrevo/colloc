import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Les 5 designs de Colloc. L'administrateur choisit le design et peut changer les couleurs :
/// le choix est enregistré côté serveur et s'applique à tous les visiteurs.
enum DesignId { ocean, soleil, minimal, nuit, pop }

enum HeaderStyle { gradient, warm, flat, glow, pop }

enum CardStyle { overlay, row, poster }

/// Réglages enregistrés (table coloc_app_settings, clé « theme »).
class ThemeSettings {
  const ThemeSettings({
    this.design = DesignId.ocean,
    this.primary,
    this.accent,
  });
  final DesignId design;
  final int? primary, accent; // ARGB, null = couleurs d'origine du design

  ThemeSettings copyWith({
    DesignId? design,
    int? primary,
    int? accent,
    bool clearColors = false,
  }) => ThemeSettings(
    design: design ?? this.design,
    primary: clearColors ? null : (primary ?? this.primary),
    accent: clearColors ? null : (accent ?? this.accent),
  );

  Map<String, dynamic> toJson() => {
    'design': design.name,
    'primary': primary,
    'accent': accent,
  };

  factory ThemeSettings.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const ThemeSettings();
    final d = DesignId.values.where((e) => e.name == j['design']);
    return ThemeSettings(
      design: d.isEmpty ? DesignId.ocean : d.first,
      primary: (j['primary'] as num?)?.toInt(),
      accent: (j['accent'] as num?)?.toInt(),
    );
  }
}

Color shade(Color c, double l) {
  final h = HSLColor.fromColor(c);
  return h.withLightness(l.clamp(0.0, 1.0)).toColor();
}

Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

class DesignSpec {
  const DesignSpec({
    required this.id,
    required this.name,
    required this.tagline,
    required this.dark,
    required this.bg,
    required this.surface,
    required this.ink,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.accent,
    required this.tertiary,
    required this.headerStyle,
    required this.headerColors,
    required this.headerInk,
    required this.headerRadius,
    required this.cardStyle,
    required this.radius,
    required this.border,
    required this.borderColor,
    required this.buttonColors,
    required this.buttonInk,
    required this.accentButtonColors,
    required this.chipSel,
    required this.chipSelInk,
    required this.chipUnsel,
    required this.chipUnselInk,
    required this.chipBorder,
    required this.offsetShadow,
    required this.sectionBar,
  });

  final DesignId id;
  final String name, tagline;
  final bool dark;
  final Color bg,
      surface,
      ink,
      primary,
      primaryDark,
      primaryLight,
      accent,
      tertiary;
  final HeaderStyle headerStyle;
  final List<Color> headerColors;
  final Color headerInk;
  final double headerRadius;
  final CardStyle cardStyle;
  final double radius, border;
  final Color borderColor;
  final List<Color> buttonColors;
  final Color buttonInk;
  final List<Color> accentButtonColors;
  final Color chipSel, chipSelInk, chipUnsel, chipUnselInk, chipBorder;
  final bool offsetShadow;
  final bool sectionBar;

  Color get muted => ink.withValues(alpha: .62);
  bool get headerIsDark => headerInk.computeLuminance() > .5;
}

DesignSpec buildDesign(ThemeSettings s) {
  switch (s.design) {
    case DesignId.ocean:
      final p = Color(s.primary ?? 0xFF0F766E),
          a = Color(s.accent ?? 0xFFF97316);
      final pd = shade(p, .22), pl = shade(p, .40);
      return DesignSpec(
        id: DesignId.ocean,
        name: 'Océan',
        tagline: 'Vert profond, dégradés, cartes à photo plein cadre',
        dark: false,
        bg: const Color(0xFFF1F6F5),
        surface: Colors.white,
        ink: const Color(0xFF0F1F1D),
        primary: p,
        primaryDark: pd,
        primaryLight: pl,
        accent: a,
        tertiary: const Color(0xFF4338CA),
        headerStyle: HeaderStyle.gradient,
        headerColors: [pd, p, pl],
        headerInk: Colors.white,
        headerRadius: 32,
        cardStyle: CardStyle.overlay,
        radius: 22,
        border: 0,
        borderColor: Colors.transparent,
        buttonColors: [pd, p, pl],
        buttonInk: Colors.white,
        accentButtonColors: [
          mix(a, Colors.black, .12),
          mix(a, Colors.white, .22),
        ],
        chipSel: Colors.white,
        chipSelInk: p,
        chipUnsel: Colors.white.withValues(alpha: .16),
        chipUnselInk: Colors.white,
        chipBorder: Colors.white.withValues(alpha: .4),
        offsetShadow: false,
        sectionBar: true,
      );
    case DesignId.soleil:
      final p = Color(s.primary ?? 0xFFD9480F),
          a = Color(s.accent ?? 0xFF0C8599);
      return DesignSpec(
        id: DesignId.soleil,
        name: 'Soleil',
        tagline: 'Chaud et lumineux, en-tête centré, grandes cartes arrondies',
        dark: false,
        bg: const Color(0xFFFFF8EE),
        surface: Colors.white,
        ink: const Color(0xFF3B1F0B),
        primary: p,
        primaryDark: shade(p, .32),
        primaryLight: shade(p, .62),
        accent: a,
        tertiary: const Color(0xFF7048E8),
        headerStyle: HeaderStyle.warm,
        headerColors: [
          mix(p, Colors.white, .86),
          mix(p, Colors.white, .70),
          mix(Color(0xFFFFC078), Colors.white, .2),
        ],
        headerInk: const Color(0xFF3B1F0B),
        headerRadius: 44,
        cardStyle: CardStyle.overlay,
        radius: 30,
        border: 0,
        borderColor: Colors.transparent,
        buttonColors: [shade(p, .38), p],
        buttonInk: Colors.white,
        accentButtonColors: [shade(a, .30), a],
        chipSel: p,
        chipSelInk: Colors.white,
        chipUnsel: Colors.white,
        chipUnselInk: const Color(0xFF3B1F0B),
        chipBorder: p.withValues(alpha: .35),
        offsetShadow: false,
        sectionBar: false,
      );
    case DesignId.minimal:
      final p = Color(s.primary ?? 0xFF111111),
          a = Color(s.accent ?? 0xFFC2410C);
      return DesignSpec(
        id: DesignId.minimal,
        name: 'Minimal',
        tagline: 'Noir et blanc, sobre, liste compacte, aucun dégradé',
        dark: false,
        bg: Colors.white,
        surface: Colors.white,
        ink: const Color(0xFF111111),
        primary: p,
        primaryDark: shade(p, .08),
        primaryLight: shade(p, .3),
        accent: a,
        tertiary: const Color(0xFF1D4ED8),
        headerStyle: HeaderStyle.flat,
        headerColors: [Colors.white, Colors.white],
        headerInk: const Color(0xFF111111),
        headerRadius: 0,
        cardStyle: CardStyle.row,
        radius: 6,
        border: 1,
        borderColor: const Color(0xFFE5E5E5),
        buttonColors: [p, p],
        buttonInk: Colors.white,
        accentButtonColors: [a, a],
        chipSel: p,
        chipSelInk: Colors.white,
        chipUnsel: Colors.white,
        chipUnselInk: const Color(0xFF111111),
        chipBorder: const Color(0xFFD4D4D4),
        offsetShadow: false,
        sectionBar: false,
      );
    case DesignId.nuit:
      final p = Color(s.primary ?? 0xFF8B5CF6),
          a = Color(s.accent ?? 0xFF22D3EE);
      return DesignSpec(
        id: DesignId.nuit,
        name: 'Nuit',
        tagline: 'Mode sombre, néons violet et cyan, cartes lumineuses',
        dark: true,
        bg: const Color(0xFF0B1020),
        surface: const Color(0xFF151B33),
        ink: const Color(0xFFF1F5F9),
        primary: p,
        primaryDark: shade(p, .30),
        primaryLight: shade(p, .72),
        accent: a,
        tertiary: const Color(0xFFF472B6),
        headerStyle: HeaderStyle.glow,
        headerColors: [const Color(0xFF1B1448), const Color(0xFF0B1020)],
        headerInk: Colors.white,
        headerRadius: 28,
        cardStyle: CardStyle.overlay,
        radius: 20,
        border: 1,
        borderColor: p.withValues(alpha: .45),
        buttonColors: [shade(p, .45), shade(p, .62)],
        buttonInk: Colors.white,
        accentButtonColors: [shade(a, .32), shade(a, .45)],
        chipSel: p,
        chipSelInk: Colors.white,
        chipUnsel: Colors.white.withValues(alpha: .06),
        chipUnselInk: const Color(0xFFE2E8F0),
        chipBorder: Colors.white.withValues(alpha: .18),
        offsetShadow: false,
        sectionBar: true,
      );
    case DesignId.pop:
      final p = Color(s.primary ?? 0xFFFF4D8D),
          a = Color(s.accent ?? 0xFF3B82F6);
      return DesignSpec(
        id: DesignId.pop,
        name: 'Pop',
        tagline: 'Jaune vif, gros contours noirs, ombres décalées, ludique',
        dark: false,
        bg: const Color(0xFFFFF4C2),
        surface: Colors.white,
        ink: const Color(0xFF111111),
        primary: p,
        primaryDark: shade(p, .35),
        primaryLight: shade(p, .8),
        accent: a,
        tertiary: const Color(0xFF22C55E),
        headerStyle: HeaderStyle.pop,
        headerColors: [const Color(0xFFFFD43B), const Color(0xFFFFD43B)],
        headerInk: const Color(0xFF111111),
        headerRadius: 0,
        cardStyle: CardStyle.poster,
        radius: 14,
        border: 3,
        borderColor: const Color(0xFF111111),
        buttonColors: [p, p],
        buttonInk: Colors.white,
        accentButtonColors: [a, a],
        chipSel: const Color(0xFF111111),
        chipSelInk: Colors.white,
        chipUnsel: Colors.white,
        chipUnselInk: const Color(0xFF111111),
        chipBorder: const Color(0xFF111111),
        offsetShadow: true,
        sectionBar: false,
      );
  }
}

/// Design courant (global : lu par les widgets, remplacé par AppState quand l'admin change le design).
class D {
  static DesignSpec s = buildDesign(const ThemeSettings());
}

/// Palettes proposées à l'administrateur.
const kSwatches = <int>[
  0xFF0F766E,
  0xFF2563EB,
  0xFF7C3AED,
  0xFFDB2777,
  0xFFDC2626,
  0xFFEA580C,
  0xFFD97706,
  0xFF65A30D,
  0xFF16A34A,
  0xFF0891B2,
  0xFF111111,
  0xFF8B5CF6,
];

/// Texte lisible (noir/blanc) sur une couleur donnée.
Color onColor(Color c) =>
    c.computeLuminance() > .55 ? const Color(0xFF111111) : Colors.white;

double sinD(double a) => math.sin(a);
