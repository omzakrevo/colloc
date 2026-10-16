import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../util/format.dart';
import 'theme.dart';

/// Photo d'annonce, ou joli visuel de remplacement coloré par type.
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
          colors: [c, Color.lerp(c, Colors.white, .45)!],
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
    final c = kindColor(kind);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: onImage
            ? Colors.white.withValues(alpha: .95)
            : c.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        boxShadow: onImage
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
          Icon(kindIcon(kind), size: 14, color: c),
          const SizedBox(width: 5),
          Text(
            kind.label,
            style: TextStyle(
              color: c,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

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

/// Bouton principal en dégradé, avec pulsation optionnelle.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.pulse = false,
    this.gradient = kBrandGradient,
    this.busy = false,
  });
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool pulse, busy;
  final LinearGradient gradient;
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
    final enabled = widget.onPressed != null && !widget.busy;
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
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (widget.gradient.colors.first).withValues(alpha: .35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: enabled ? widget.onPressed : null,
              child: SizedBox(
                height: 54,
                child: Center(
                  child: widget.busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon, color: Colors.white),
                              const SizedBox(width: 10),
                            ],
                            Text(
                              widget.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
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

/// Bandeau en dégradé à coins arrondis, avec bulles décoratives.
class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 22),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: kBrandGradient,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
    ),
    child: ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -40,
            child: CircleAvatar(
              radius: 110,
              backgroundColor: Colors.white.withValues(alpha: .08),
            ),
          ),
          Positioned(
            left: -60,
            bottom: -70,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: kAccent.withValues(alpha: .18),
            ),
          ),
          Positioned(
            right: 70,
            bottom: 10,
            child: CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white.withValues(alpha: .07),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(padding: padding, child: child),
          ),
        ],
      ),
    ),
  );
}

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.onTap});
  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    final t = Theme.of(context).textTheme;
    final isReq = l.kind == ListingKind.request;
    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: kBrand.withValues(alpha: .10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
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
                    child: PhotoView(
                      photo: l.photos.isEmpty ? null : l.photos.first,
                      kind: l.kind,
                    ),
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
                            text: isReq
                                ? 'Budget ${fcfa(l.rent)}'
                                : fcfa(l.rent),
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
                        shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
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
                    Row(
                      children: [
                        const Icon(Icons.place, size: 15, color: kAccent),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${l.neighborhood.isEmpty ? '' : '${l.neighborhood}, '}${l.city}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: kindColor(l.kind)
                              .withValues(alpha: .15),
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
                            style: t.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        if (l.kind.hasHouse) _SpotsChip(l.spots),
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
  }
}

class _SpotsChip extends StatelessWidget {
  const _SpotsChip(this.n);
  final int n;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: kAccent.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      '$n place${n > 1 ? 's' : ''}',
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFFC2410C),
      ),
    ),
  );
}

/// Slider de l'accueil : défile tout seul, glissable, points animés.
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
          height: 150,
          child: PageView.builder(
            controller: _pc,
            itemCount: n,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => AnimatedBuilder(
              animation: _pc,
              builder: (_, child) {
                final page = _pc.hasClients && _pc.position.haveDimensions
                    ? (_pc.page ?? 0)
                    : 0.0;
                final d = (page - i).abs().clamp(0.0, 1.0);
                return Transform.scale(
                  scale: 1 - .07 * d,
                  child: Opacity(opacity: 1 - .35 * d, child: child),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _PromoSlide(widget.promos[i]),
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

class _PromoSlide extends StatelessWidget {
  const _PromoSlide(this.p);
  final Promo p;
  @override
  Widget build(BuildContext context) {
    final a = Color(p.colorA), b = Color(p.colorB);
    return GestureDetector(
      onTap: p.linkUrl == null
          ? null
          : () => launchUrl(
              Uri.parse(p.linkUrl!),
              mode: LaunchMode.externalApplication,
            ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [a, b],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: a.withValues(alpha: .35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (p.imageUrl != null)
              Image.network(
                p.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(),
              ),
            if (p.imageUrl != null)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
              ),
            Positioned(
              right: -30,
              top: -30,
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.white.withValues(alpha: .13),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -40,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.white.withValues(alpha: .10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (p.sponsor)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PUBLICITÉ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  Text(
                    p.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
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
                        color: Colors.white.withValues(alpha: .92),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
