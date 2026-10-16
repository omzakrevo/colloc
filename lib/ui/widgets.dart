import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import 'design.dart';
import 'theme.dart';

// ───────────────────────── photos / badges ─────────────────────────

/// Photo d'annonce, ou visuel coloré de remplacement selon le type.
class PhotoView extends StatelessWidget {
  const PhotoView({
    super.key,
    required this.photo,
    required this.kind,
    this.fit = BoxFit.cover,
  });
  final Photo? photo;
  final ListingKind kind;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final c = kindColor(kind);
    final placeholder = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c, mix(c, Colors.white, .45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.white.withValues(alpha: .12),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -50,
            child: CircleAvatar(
              radius: 90,
              backgroundColor: Colors.white.withValues(alpha: .10),
            ),
          ),
          Center(
            child: Icon(
              kindIcon(kind),
              size: 56,
              color: Colors.white.withValues(alpha: .9),
            ),
          ),
        ],
      ),
    );
    final p = photo;
    if (p == null) return placeholder;
    if (p.bytes != null) return Image.memory(p.bytes!, fit: fit);
    if (p.asset != null)
      return Image.asset(
        p.asset!,
        fit: fit,
        errorBuilder: (_, _, _) => placeholder,
      );
    return Image.network(
      p.url!,
      fit: fit,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (_, child, prog) => prog == null ? child : placeholder,
    );
  }
}

class KindBadge extends StatelessWidget {
  const KindBadge(this.kind, {super.key, this.onImage = false});
  final ListingKind kind;
  final bool onImage;
  @override
  Widget build(BuildContext context) {
    final d = D.s;
    final c = kindColor(kind);
    final pop = d.id == DesignId.pop;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: onImage
            ? (d.dark
                  ? d.surface.withValues(alpha: .92)
                  : Colors.white.withValues(alpha: .95))
            : c.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(
          pop || d.id == DesignId.minimal ? 6 : 20,
        ),
        border: pop ? Border.all(color: d.ink, width: 2) : null,
        boxShadow: onImage && !pop
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .15),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(kindIcon(kind), size: 14, color: pop ? d.ink : c),
          const SizedBox(width: 5),
          Text(
            kind.label,
            style: TextStyle(
              color: pop ? d.ink : c,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── animations ─────────────────────────

/// Apparition en fondu + glissement, échelonnée selon [index].
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;
  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final int _delay = (widget.index.clamp(0, 8)) * 80;
  late final _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 500 + _delay),
  )..forward();
  late final _a = CurvedAnimation(
    parent: _c,
    curve: Interval(_delay / (500 + _delay), 1, curve: Curves.easeOutCubic),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _a,
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0, .12),
        end: Offset.zero,
      ).animate(_a),
      child: widget.child,
    ),
  );
}

/// Effet « ressort » au survol (web) et à l'appui.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _hover = false, _down = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? .97 : (_hover ? 1.02 : 1),
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    ),
  );
}

// ───────────────────────── éléments de design ─────────────────────────

/// Décoration d'une carte selon le design courant (ombre douce, contour, ombre décalée « pop »…).
BoxDecoration cardDecoration({Color? color, double? radius}) {
  final d = D.s;
  return BoxDecoration(
    color: color ?? d.surface,
    borderRadius: BorderRadius.circular(radius ?? d.radius),
    border: d.border > 0
        ? Border.all(color: d.borderColor, width: d.border)
        : null,
    boxShadow: d.offsetShadow
        ? [BoxShadow(color: d.ink, offset: const Offset(5, 5), blurRadius: 0)]
        : d.id == DesignId.minimal
        ? null
        : d.dark
        ? [
            BoxShadow(
              color: d.primary.withValues(alpha: .18),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ]
        : [
            BoxShadow(
              color: d.primary.withValues(alpha: .10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
  );
}

/// Bouton principal du design (dégradé, plein, ou « pop » avec ombre décalée), pulsation optionnelle.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.pulse = false,
    this.gradient,
    this.busy = false,
  });
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool pulse, busy;
  final LinearGradient? gradient;
  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = D.s;
    final g = widget.gradient ?? kBrandGradient;
    final ink = onColor(mix(g.colors.first, g.colors.last, .5));
    final enabled = widget.onPressed != null && !widget.busy;
    final r = d.id == DesignId.minimal
        ? 6.0
        : (d.id == DesignId.pop ? 14.0 : 16.0);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.scale(
        scale: 1 + .025 * Curves.easeInOut.transform(_c.value),
        child: child,
      ),
      child: Opacity(
        opacity: widget.onPressed == null ? .6 : 1,
        child: Container(
          decoration: BoxDecoration(
            gradient: g,
            borderRadius: BorderRadius.circular(r),
            border: d.id == DesignId.pop
                ? Border.all(color: d.ink, width: 3)
                : null,
            boxShadow: d.offsetShadow
                ? [
                    BoxShadow(
                      color: d.ink,
                      offset: const Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ]
                : d.id == DesignId.minimal
                ? null
                : [
                    BoxShadow(
                      color: g.colors.first.withValues(alpha: .35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(r),
              onTap: enabled ? widget.onPressed : null,
              child: SizedBox(
                height: 54,
                child: Center(
                  child: widget.busy
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: ink,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon, color: ink),
                              const SizedBox(width: 10),
                            ],
                            Flexible(
                              child: Text(
                                widget.label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastille de filtre (catégories, villes, onglets admin) : style propre à chaque design.
class DesignChip extends StatelessWidget {
  const DesignChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.onHeader = true,
  });
  final String label;
  final IconData? icon;
  final bool selected, onHeader;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final d = D.s;
    // sur le fond de la page (hors en-tête) : pastille neutre, lisible dans tous les designs
    final selFill = onHeader ? d.chipSel : d.primary;
    final selInk = onHeader ? d.chipSelInk : onColor(d.primary);
    final unselFill = onHeader ? d.chipUnsel : d.surface;
    final unselInk = onHeader ? d.chipUnselInk : d.ink;
    final border = onHeader
        ? d.chipBorder
        : (d.id == DesignId.pop ? d.ink : d.ink.withValues(alpha: .2));
    final fg = selected ? selInk : unselInk;
    final r = d.id == DesignId.minimal
        ? 6.0
        : (d.id == DesignId.pop ? 10.0 : 30.0);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? selFill : unselFill,
            borderRadius: BorderRadius.circular(r),
            border: Border.all(
              color: border,
              width: d.id == DesignId.pop ? 2.5 : 1,
            ),
            boxShadow: d.id == DesignId.pop && selected
                ? [
                    BoxShadow(
                      color: d.ink,
                      offset: const Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Titre de section, décoré selon le design.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final d = D.s;
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        if (d.sectionBar) ...[
          Container(
            width: 5,
            height: 22,
            decoration: BoxDecoration(
              gradient: kAccentGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
        ],
        if (d.id == DesignId.pop)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: d.primary,
              border: Border.all(color: d.ink, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: d.ink,
                  offset: const Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Text(
              text.toUpperCase(),
              style: t.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          )
        else
          Text(
            d.id == DesignId.minimal ? text.toUpperCase() : text,
            style: t.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: d.id == DesignId.minimal ? 1.5 : 0,
              fontSize: d.id == DesignId.minimal ? 14 : null,
            ),
          ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// En-tête de page : dégradé animé (Océan), chaud et centré (Soleil), plat (Minimal), néon (Nuit) ou jaune à contours (Pop).
class GradientHeader extends StatefulWidget {
  const GradientHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 22),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  State<GradientHeader> createState() => _GradientHeaderState();
}

class _GradientHeaderState extends State<GradientHeader>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _circle(double r, Color c) =>
      CircleAvatar(radius: r, backgroundColor: c);

  @override
  Widget build(BuildContext context) {
    final d = D.s;
    final radius = BorderRadius.vertical(
      bottom: Radius.circular(d.headerRadius),
    );
    final flat = d.headerStyle == HeaderStyle.flat,
        pop = d.headerStyle == HeaderStyle.pop;
    final deco = BoxDecoration(
      gradient: flat || pop
          ? null
          : LinearGradient(
              colors: d.headerColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      color: flat ? d.surface : (pop ? d.headerColors.first : null),
      borderRadius: radius,
      border: flat
          ? Border(bottom: BorderSide(color: d.borderColor))
          : (pop ? Border(bottom: BorderSide(color: d.ink, width: 3)) : null),
      boxShadow: d.headerStyle == HeaderStyle.warm
          ? [
              BoxShadow(
                color: d.primary.withValues(alpha: .18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ]
          : (pop
                ? [
                    BoxShadow(
                      color: d.ink,
                      offset: const Offset(0, 6),
                      blurRadius: 0,
                    ),
                  ]
                : null),
    );
    Widget deco_() {
      switch (d.headerStyle) {
        case HeaderStyle.flat:
          return const SizedBox.shrink();
        case HeaderStyle.pop:
          return Stack(
            children: [
              Positioned(
                right: 10,
                top: 78,
                child: Transform.rotate(
                  angle: .3,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: d.primary,
                      border: Border.all(color: d.ink, width: 3),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 90,
                bottom: 14,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: d.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: d.ink, width: 3),
                  ),
                ),
              ),
              Positioned(
                left: 150,
                top: 10,
                child: Transform.rotate(
                  angle: -.4,
                  child: Icon(Icons.star_rounded, size: 30, color: d.ink),
                ),
              ),
            ],
          );
        default:
          return AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              final a = _c.value * 2 * math.pi;
              final glow = d.headerStyle == HeaderStyle.glow,
                  warm = d.headerStyle == HeaderStyle.warm;
              return Stack(
                children: [
                  Positioned(
                    right: -50 + 14 * math.sin(a),
                    top: -40 + 10 * math.cos(a),
                    child: _circle(
                      warm ? 120 : 110,
                      glow
                          ? d.primary.withValues(alpha: .28)
                          : (warm
                                ? const Color(0xFFFFC078).withValues(alpha: .55)
                                : Colors.white.withValues(alpha: .08)),
                    ),
                  ),
                  Positioned(
                    left: -60 + 12 * math.cos(a),
                    bottom: -70 + 14 * math.sin(a),
                    child: _circle(
                      100,
                      glow
                          ? d.accent.withValues(alpha: .20)
                          : (warm
                                ? d.primary.withValues(alpha: .14)
                                : d.accent.withValues(alpha: .18)),
                    ),
                  ),
                  Positioned(
                    right: 70 + 20 * math.sin(a + 1),
                    bottom: 10 + 8 * math.cos(a + 2),
                    child: _circle(
                      26,
                      Colors.white.withValues(alpha: warm ? .5 : .08),
                    ),
                  ),
                  Positioned(
                    left: 150 + 16 * math.cos(a + 3),
                    top: 20 + 10 * math.sin(a),
                    child: _circle(
                      12,
                      Colors.white.withValues(alpha: warm ? .5 : .10),
                    ),
                  ),
                ],
              );
            },
          );
      }
    }

    return Container(
      decoration: deco,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(child: deco_()),
            SafeArea(
              bottom: false,
              child: Padding(padding: widget.padding, child: widget.child),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte « squelette » qui scintille pendant le chargement.
class SkeletonCard extends StatefulWidget {
  const SkeletonCard({super.key});
  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = D.s;
    final base = d.dark ? const Color(0xFF1E2542) : Colors.grey.shade200;
    final hi = d.dark ? const Color(0xFF2B3566) : Colors.grey.shade50;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final x = -1 + 3 * _c.value;
        Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        );
        return Container(
          decoration: cardDecoration(),
          clipBehavior: Clip.antiAlias,
          child: ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (r) => LinearGradient(
              begin: Alignment(x - 1, 0),
              end: Alignment(x + 1, 0),
              colors: [base, hi, base],
            ).createShader(r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 120, color: Colors.white),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(200, 16),
                      const SizedBox(height: 10),
                      bar(120, 12),
                      const SizedBox(height: 18),
                      bar(160, 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ───────────────────────── cartes d'annonces ─────────────────────────

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.onTap});
  final Listing listing;
  final VoidCallback onTap;

  static SliverGridDelegate gridDelegate() => switch (D.s.cardStyle) {
    CardStyle.row => const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 640,
      mainAxisExtent: 140,
      crossAxisSpacing: 16,
      mainAxisSpacing: 12,
    ),
    CardStyle.poster => const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 430,
      mainAxisExtent: 318,
      crossAxisSpacing: 20,
      mainAxisSpacing: 22,
    ),
    CardStyle.overlay => const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 430,
      mainAxisExtent: 300,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
    ),
  };

  String _price(Listing l) =>
      l.kind == ListingKind.request ? 'Budget ${fcfa(l.rent)}' : fcfa(l.rent);

  Widget _meta(BuildContext context, Listing l, {bool showSpots = true}) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: kindColor(l.kind).withValues(alpha: .18),
          child: Text(
            l.ownerName.characters.first.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: kindColor(l.kind),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${l.ownerName} · ${ago(l.createdAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.bodySmall?.copyWith(color: D.s.muted),
          ),
        ),
        if (l.kind.hasHouse && showSpots) _SpotsChip(l.spots),
      ],
    );
  }

  Widget _where(BuildContext context, Listing l) => Row(
    children: [
      Icon(Icons.place, size: 15, color: kAccent),
      const SizedBox(width: 3),
      Expanded(
        child: Text(
          '${l.neighborhood.isEmpty ? '' : '${l.neighborhood}, '}${l.city}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ],
  );

  Widget _newTag(Listing l, double right) =>
      DateTime.now().difference(l.createdAt).inHours < 24
      ? Positioned(
          top: 10,
          right: right,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              gradient: kAccentGradient,
              borderRadius: BorderRadius.circular(
                D.s.id == DesignId.pop ? 4 : 12,
              ),
              border: D.s.id == DesignId.pop
                  ? Border.all(color: D.s.ink, width: 2)
                  : null,
            ),
            child: Text(
              'NOUVEAU',
              style: TextStyle(
                color: onColor(D.s.accent),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: .6,
              ),
            ),
          ),
        )
      : const SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    final l = listing;
    final t = Theme.of(context).textTheme;
    final d = D.s;
    final photo = l.photos.isEmpty ? null : l.photos.first;
    switch (d.cardStyle) {
      case CardStyle.row:
        return Pressable(
          onTap: onTap,
          child: Container(
            decoration: cardDecoration(),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                SizedBox(
                  width: 130,
                  height: double.infinity,
                  child: Hero(
                    tag: 'photo-${l.id}',
                    child: PhotoView(photo: photo, kind: l.kind),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.kind.label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                            color: kindColor(l.kind),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        _where(context, l),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              _price(l),
                              style: t.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(' /mois', style: t.bodySmall),
                            const Spacer(),
                            Text(
                              ago(l.createdAt),
                              style: t.bodySmall?.copyWith(color: d.muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case CardStyle.poster:
        return Pressable(
          onTap: onTap,
          child: Container(
            decoration: cardDecoration(),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 168,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'photo-${l.id}',
                        child: PhotoView(photo: photo, kind: l.kind),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: KindBadge(l.kind, onImage: true),
                      ),
                      _newTag(l, 10),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Transform.rotate(
                          angle: -.06,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: d.headerColors.first,
                              border: Border.all(color: d.ink, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: d.ink,
                                  offset: const Offset(3, 3),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Text(
                              '${_price(l)}/mois',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: d.ink,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 3, color: d.ink),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _where(context, l),
                        const Spacer(),
                        _meta(context, l),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case CardStyle.overlay:
        return Pressable(
          onTap: onTap,
          child: Container(
            decoration: cardDecoration(),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 160,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'photo-${l.id}',
                        child: PhotoView(photo: photo, kind: l.kind),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                            stops: [.5, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: KindBadge(l.kind, onImage: true),
                      ),
                      _newTag(l, l.photos.length > 1 ? 58 : 10),
                      if (l.photos.length > 1)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.photo_library_outlined,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${l.photos.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        left: 12,
                        bottom: 10,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: _price(l),
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const TextSpan(
                                text: ' /mois',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            shadows: [
                              Shadow(blurRadius: 8, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _where(context, l),
                        const Spacer(),
                        _meta(context, l),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}

class _SpotsChip extends StatelessWidget {
  const _SpotsChip(this.n);
  final int n;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: kAccent.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      '$n place${n > 1 ? 's' : ''}',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: D.s.dark ? kAccent : mix(kAccent, Colors.black, .3),
      ),
    ),
  );
}

// ───────────────────────── slider de flyers ─────────────────────────

/// Slider d'accueil : défile tout seul, glissable ; chaque flyer est cliquable (affichage plein écran + lien).
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key, required this.promos});
  final List<Promo> promos;
  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final _pc = PageController(viewportFraction: .9);
  Timer? _timer;
  int _page = 0;
  final _seen = <String>{};

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pc.hasClients || widget.promos.length < 2) return;
      _pc.animateToPage(
        (_page + 1) % widget.promos.length,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _impression(0));
  }

  void _impression(int i) {
    if (!mounted || i >= widget.promos.length) return;
    final p = widget.promos[i];
    if (_seen.add(p.id))
      AppScope.of(context).track('promo_view', promoId: p.id);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.promos.length;
    return Column(
      children: [
        SizedBox(
          height: 162,
          child: PageView.builder(
            controller: _pc,
            itemCount: n,
            onPageChanged: (i) {
              setState(() => _page = i);
              _impression(i);
            },
            itemBuilder: (_, i) => AnimatedBuilder(
              animation: _pc,
              builder: (_, child) {
                final page = _pc.hasClients && _pc.position.haveDimensions
                    ? (_pc.page ?? 0)
                    : 0.0;
                final dd = (page - i).abs().clamp(0.0, 1.0);
                return Transform.scale(
                  scale: 1 - .07 * dd,
                  child: Opacity(opacity: 1 - .35 * dd, child: child),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                child: PromoSlide(widget.promos[i]),
              ),
            ),
          ),
        ),
        if (n > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < n; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 7,
                  width: i == _page ? 22 : 7,
                  decoration: BoxDecoration(
                    color: i == _page ? kBrand : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

Widget promoImage(Promo p, {BoxFit fit = BoxFit.cover}) {
  if (p.imageBytes != null) return Image.memory(p.imageBytes!, fit: fit);
  if (p.imageUrl != null)
    return Image.network(
      p.imageUrl!,
      fit: fit,
      errorBuilder: (_, _, _) => const SizedBox(),
    );
  return const SizedBox();
}

/// Un flyer : image plein cadre si fournie, sinon dégradé + texte (couleur du texte choisie selon la luminosité du fond).
class PromoSlide extends StatelessWidget {
  const PromoSlide(this.p, {super.key, this.interactive = true});
  final Promo p;
  final bool interactive;
  @override
  Widget build(BuildContext context) {
    final d = D.s;
    final a = Color(p.colorA), b = Color(p.colorB);
    final hasImage = p.hasImage;
    final light =
        !hasImage && a.computeLuminance() + b.computeLuminance() > 1.0;
    final fg = hasImage
        ? Colors.white
        : (light ? const Color(0xFF111111) : Colors.white);
    final r = d.id == DesignId.minimal
        ? 8.0
        : (d.id == DesignId.pop ? 14.0 : 24.0);
    return GestureDetector(
      onTap: interactive ? () => openFlyer(context, p) : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [a, b],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(r),
          border: d.border > 0 && d.id != DesignId.minimal
              ? Border.all(
                  color: d.id == DesignId.pop ? d.ink : d.borderColor,
                  width: d.border,
                )
              : null,
          boxShadow: d.offsetShadow
              ? [
                  BoxShadow(
                    color: d.ink,
                    offset: const Offset(5, 5),
                    blurRadius: 0,
                  ),
                ]
              : [
                  BoxShadow(
                    color: a.withValues(alpha: .30),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage) promoImage(p),
            if (hasImage)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                    stops: [0, .7],
                  ),
                ),
              ),
            if (!hasImage)
              Positioned(
                right: -30,
                top: -30,
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.white.withValues(
                    alpha: light ? .5 : .13,
                  ),
                ),
              ),
            if (!hasImage)
              Positioned(
                right: 30,
                bottom: -40,
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white.withValues(
                    alpha: light ? .4 : .10,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: hasImage
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.center,
                children: [
                  if (p.sponsor)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: light ? kAccent : Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'PUBLICITÉ',
                        style: TextStyle(
                          color: light ? onColor(kAccent) : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  if (p.title.isNotEmpty)
                    Text(
                      p.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  if (p.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      p.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg.withValues(alpha: .88),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (interactive && p.linkUrl != null && p.linkUrl!.isNotEmpty)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.open_in_new_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Clic sur un flyer : compte le clic, affiche le flyer en grand et propose d'ouvrir le lien.
Future<void> openFlyer(BuildContext context, Promo p) async {
  AppScope.of(context).track('promo_click', promoId: p.id);
  await showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: p.hasImage
                  ? InteractiveViewer(child: promoImage(p, fit: BoxFit.contain))
                  : SizedBox(
                      height: 260,
                      child: PromoSlide(p, interactive: false),
                    ),
            ),
            if (p.hasImage && (p.title.isNotEmpty || p.subtitle.isNotEmpty))
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(14),
                decoration: cardDecoration(radius: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.title.isNotEmpty)
                      Text(
                        p.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    if (p.subtitle.isNotEmpty) Text(p.subtitle),
                  ],
                ),
              ),
            if (p.linkUrl != null && p.linkUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              GradientButton(
                label: 'Ouvrir le lien',
                icon: Icons.open_in_new_rounded,
                onPressed: () {
                  launchUrl(
                    Uri.parse(p.linkUrl!),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

// ───────────────────────── divers ─────────────────────────

/// Boutons Appeler / WhatsApp pour un contact débloqué.
class ContactActions extends StatelessWidget {
  const ContactActions(this.contact, {super.key});
  final UnlockedContact contact;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: GradientButton(
          label: contact.phone,
          icon: Icons.call,
          onPressed: () =>
              launchUrl(Uri.parse('tel:${cleanPhone(contact.phone)}')),
        ),
      ),
      const SizedBox(width: 10),
      Material(
        color: const Color(0xFF22C55E),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => launchUrl(
            Uri.parse(
              'https://wa.me/${cleanPhone(contact.phone).replaceAll('+', '')}',
            ),
            mode: LaunchMode.externalApplication,
          ),
          child: const SizedBox(
            width: 54,
            height: 54,
            child: Icon(Icons.chat, color: Colors.white),
          ),
        ),
      ),
    ],
  );
}

void toast(BuildContext context, String msg) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(
    SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
  );
