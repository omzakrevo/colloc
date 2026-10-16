import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import 'auth_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final f = s.filter;
    final t = Theme.of(context).textTheme;

    Widget pill(String label, IconData icon, ListingKind? k) {
      final sel = f.kind == k;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => s.setFilter(
            ListingFilter(kind: k, query: f.query, maxRent: f.maxRent),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: sel ? Colors.white : Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: sel ? 1 : .35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: sel ? kBrand : Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: sel ? kBrand : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final header = GradientHeader(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ColocLogo(size: 40),
                  const SizedBox(width: 10),
                  const Text(
                    'Colloc',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .3,
                    ),
                  ),
                  const Spacer(),
                  if (s.user == null)
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      ),
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text('Connexion'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        shape: const StadiumBorder(),
                      ),
                    )
                  else
                    Text(
                      'Salut, ${s.user!.displayName.split(' ').first}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
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
                child: const Text(
                  'Trouve ta coloc,\nsans prise de tête.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
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
                    prefixIcon: const Icon(Icons.search, color: kBrand),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: f.query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _search.clear();
                              s.setFilter(
                                ListingFilter(kind: f.kind, maxRent: f.maxRent),
                              );
                            },
                          ),
                  ),
                  onSubmitted: (v) => s.setFilter(
                    ListingFilter(kind: f.kind, query: v, maxRent: f.maxRent),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    pill('Tout', Icons.grid_view_rounded, null),
                    pill(
                      'Colocations',
                      Icons.home_work_outlined,
                      ListingKind.offer,
                    ),
                    pill(
                      'Demandes',
                      Icons.person_search_outlined,
                      ListingKind.request,
                    ),
                    pill(
                      'Agences',
                      Icons.apartment_outlined,
                      ListingKind.agency,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Widget center(Widget w) => Center(
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
                child: center(PromoCarousel(promos: s.promos)),
              ),
            ),
          SliverToBoxAdapter(
            child: center(
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: kAccentGradient,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'À la une',
                      style: t.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    if (!s.loading)
                      Text(
                        '${s.listings.length} annonce${s.listings.length > 1 ? 's' : ''}',
                        style: t.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (s.loading)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 430,
                  mainAxisExtent: 300,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
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
                          'Aucune annonce pour le moment.\nSoyez le premier à publier !',
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
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 430,
                          mainAxisExtent: 300,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
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
          SliverToBoxAdapter(child: center(const _HowItWorks())),
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
    const steps = [
      (
        Icons.search_rounded,
        'Trouve',
        "Parcours les maisons et les demandes, filtre par ville ou quartier.",
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
          Row(
            children: [
              Container(
                width: 5,
                height: 22,
                decoration: BoxDecoration(
                  gradient: kAccentGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Comment ça marche',
                style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < steps.length; i++)
            FadeSlideIn(
              index: i,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: steps[i].$4.withValues(alpha: .10),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            steps[i].$4,
                            Color.lerp(steps[i].$4, Colors.white, .35)!,
                          ],
                        ),
                      ),
                      child: Icon(steps[i].$1, color: Colors.white),
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
