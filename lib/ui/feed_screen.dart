import 'package:flutter/material.dart';

import '../cities.dart';
import '../models.dart';
import '../state/app_state.dart';
import 'auth_screen.dart';
import 'design.dart';
import 'detail_screen.dart';
import 'logo.dart';
import 'theme.dart';
import 'widgets.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  ListingFilter _f(
    AppState s, {
    Object? kind = _keep,
    Object? city = _keep,
    String? query,
  }) {
    final f = s.filter;
    return ListingFilter(
      kind: identical(kind, _keep) ? f.kind : kind as ListingKind?,
      city: identical(city, _keep) ? f.city : city as String?,
      query: query ?? f.query,
      maxRent: f.maxRent,
    );
  }

  static const _keep = Object();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final f = s.filter;
    final d = D.s;
    final t = Theme.of(context).textTheme;
    final center = d.headerStyle == HeaderStyle.warm;
    final ink = d.headerInk;

    final header = GradientHeader(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: center
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: center
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  const ColocLogo(size: 40),
                  const SizedBox(width: 10),
                  Text(
                    'Colloc',
                    style: TextStyle(
                      color: ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .3,
                    ),
                  ),
                  if (!center) ...[
                    const Spacer(),
                    if (s.user == null)
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        ),
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('Connexion'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ink,
                          side: BorderSide(
                            color: ink.withValues(alpha: .6),
                            width: d.id == DesignId.pop ? 2.5 : 1,
                          ),
                          shape:
                              d.id == DesignId.minimal || d.id == DesignId.pop
                              ? RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                )
                              : const StadiumBorder(),
                        ),
                      )
                    else
                      Text(
                        'Salut, ${s.user!.displayName.split(' ').first}',
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ],
              ),
              if (center && s.user == null)
                TextButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const AuthScreen())),
                  child: Text(
                    'Connexion',
                    style: TextStyle(color: ink, fontWeight: FontWeight.w800),
                  ),
                ),
              SizedBox(height: center ? 8 : 18),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - v)),
                    child: child,
                  ),
                ),
                child: Text(
                  'Trouve ta coloc,\nsans prise de tête.',
                  textAlign: center ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    color: ink,
                    fontSize: d.id == DesignId.minimal ? 26 : 28,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    d.id == DesignId.pop
                        ? 10
                        : (d.id == DesignId.minimal ? 6 : 18),
                  ),
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
                            color: Colors.black.withValues(alpha: .18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Ville, quartier, mot-clé…',
                    prefixIcon: Icon(Icons.search, color: kBrand),
                    suffixIcon: f.query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _search.clear();
                              s.setFilter(_f(s, query: ''));
                            },
                          ),
                  ),
                  onSubmitted: (v) => s.setFilter(_f(s, query: v)),
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    DesignChip(
                      label: 'Tout',
                      icon: Icons.grid_view_rounded,
                      selected: f.kind == null,
                      onTap: () => s.setFilter(_f(s, kind: null)),
                    ),
                    DesignChip(
                      label: 'Colocations',
                      icon: Icons.home_work_outlined,
                      selected: f.kind == ListingKind.offer,
                      onTap: () => s.setFilter(_f(s, kind: ListingKind.offer)),
                    ),
                    DesignChip(
                      label: 'Demandes',
                      icon: Icons.person_search_outlined,
                      selected: f.kind == ListingKind.request,
                      onTap: () =>
                          s.setFilter(_f(s, kind: ListingKind.request)),
                    ),
                    DesignChip(
                      label: 'Agences',
                      icon: Icons.apartment_outlined,
                      selected: f.kind == ListingKind.agency,
                      onTap: () => s.setFilter(_f(s, kind: ListingKind.agency)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    DesignChip(
                      label: 'Toutes les villes',
                      icon: Icons.place_outlined,
                      selected: f.city == null,
                      onTap: () => s.setFilter(_f(s, city: null)),
                    ),
                    for (final c in kCities)
                      DesignChip(
                        label: c.name,
                        selected: f.city == c.name,
                        onTap: () => s.setFilter(_f(s, city: c.name)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Widget wrap(Widget w) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: w,
      ),
    );

    return RefreshIndicator(
      onRefresh: () async {
        await s.loadPromos();
        await s.refresh();
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: header),
          if (s.promos.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 18),
                child: wrap(
                  PromoCarousel(
                    key: ValueKey(
                      s.promos
                          .map((p) => '${p.id}${p.title}${p.sort}${p.hasImage}')
                          .join(),
                    ),
                    promos: s.promos,
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: wrap(
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                child: SectionTitle(
                  'À la une',
                  trailing: s.loading
                      ? null
                      : Text(
                          '${s.listings.length} annonce${s.listings.length > 1 ? 's' : ''}',
                          style: t.bodySmall?.copyWith(
                            color: d.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
          if (s.loading)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverGrid.builder(
                gridDelegate: ListingCard.gridDelegate(),
                itemCount: 4,
                itemBuilder: (_, _) => const SkeletonCard(),
              ),
            )
          else if (s.error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.error!),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: s.refresh,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          else if (s.listings.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: FadeSlideIn(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.house_siding_rounded,
                          size: 72,
                          color: kBrand.withValues(alpha: .4),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Aucune annonce pour ce filtre.\nSoyez le premier à publier !',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            SliverLayoutBuilder(
              builder: (context, c) {
                final w = c.crossAxisExtent.clamp(0.0, 900.0);
                final pad = (c.crossAxisExtent - w) / 2 + 20;
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 0, pad, 28),
                  sliver: SliverGrid.builder(
                    gridDelegate: ListingCard.gridDelegate(),
                    itemCount: s.listings.length,
                    itemBuilder: (_, i) => FadeSlideIn(
                      key: ValueKey(s.listings[i].id),
                      index: i,
                      child: ListingCard(
                        listing: s.listings[i],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                DetailScreen(listing: s.listings[i]),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          SliverToBoxAdapter(child: wrap(const _HowItWorks())),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final steps = [
      (
        Icons.search_rounded,
        'Trouve',
        'Parcours les maisons et les demandes, filtre par ville ou quartier.',
        kBrand,
      ),
      (
        Icons.lock_open_rounded,
        'Contacte',
        '1 000 FCFA par mise en contact, validée par notre équipe.',
        kAccent,
      ),
      (
        Icons.key_rounded,
        'Emménage',
        'Appelle ou écris sur WhatsApp, visitez et installez-vous.',
        kIndigo,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Comment ça marche'),
          const SizedBox(height: 14),
          for (var i = 0; i < steps.length; i++)
            FadeSlideIn(
              index: i,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: cardDecoration(radius: D.s.radius.clamp(6, 20)),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: D.s.id == DesignId.minimal
                            ? BoxShape.rectangle
                            : BoxShape.circle,
                        borderRadius: D.s.id == DesignId.minimal
                            ? BorderRadius.circular(6)
                            : null,
                        color: steps[i].$4,
                        border: D.s.id == DesignId.pop
                            ? Border.all(color: D.s.ink, width: 2.5)
                            : null,
                      ),
                      child: Icon(steps[i].$1, color: onColor(steps[i].$4)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${i + 1}. ${steps[i].$2}',
                            style: t.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(steps[i].$3, style: t.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
