import 'package:flutter/material.dart';

import '../config.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import 'auth_screen.dart';
import 'pay_sheet.dart';
import 'theme.dart';
import 'widgets.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.listing});
  final Listing listing;
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _page = PageController();
  int _idx = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _contact() async {
    final s = AppScope.of(context);
    if (s.user == null) {
      final ok = await Navigator.of(context)
          .push<bool>(MaterialPageRoute(builder: (_) => const AuthScreen()));
      if (ok != true || !mounted) return;
    }
    await showPaySheet(context, widget.listing);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final l = widget.listing;
    final t = Theme.of(context).textTheme;
    final unlocked = s.contactFor(l.id);
    final pending = s.paymentFor(l.id);
    final mine = s.user?.id == l.ownerId;
    final kc = kindColor(l.kind);

    Widget row(String k, int v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(k, style: t.bodyMedium)),
          Text(
            v == 0 ? 'Aucune' : fcfa(v),
            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );

    Widget section(String title, Widget body, {int i = 0}) => FadeSlideIn(
      index: i,
      child: Padding(
        padding: const EdgeInsets.only(top: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: kc,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 8),
            body,
          ],
        ),
      ),
    );

    final photos = l.photos.isEmpty
        ? [PhotoView(photo: null, kind: l.kind)]
        : [for (final p in l.photos) PhotoView(photo: p, kind: l.kind)];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: l.kind.hasHouse ? 320 : 200,
            backgroundColor: kc,
            foregroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black38,
                child: BackButton(
                  color: Colors.white,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'photo-${l.id}',
                    child: PageView(
                      controller: _page,
                      onPageChanged: (i) => setState(() => _idx = i),
                      children: photos,
                    ),
                  ),
                  const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black38,
                            Colors.transparent,
                            Colors.black45,
                          ],
                          stops: [0, .4, 1],
                        ),
                      ),
                    ),
                  ),
                  if (l.photos.length > 1)
                    Positioned(
                      bottom: 14,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < l.photos.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              height: 7,
                              width: i == _idx ? 22 : 7,
                              decoration: BoxDecoration(
                                color: i == _idx
                                    ? Colors.white
                                    : Colors.white54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeSlideIn(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            KindBadge(l.kind),
                            const SizedBox(height: 10),
                            Text(
                              l.title,
                              style: t.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.place,
                                  size: 18,
                                  color: kAccent,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${l.neighborhood.isEmpty ? '' : '${l.neighborhood}, '}${l.city}',
                                    style: t.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      section(
                        l.kind == ListingKind.request ? 'Budget' : 'Prix',
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: kc.withValues(alpha: .12),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: l.kind == ListingKind.request
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Budget maximum / mois',
                                        style: t.bodyMedium,
                                      ),
                                    ),
                                    Text(
                                      fcfa(l.rent),
                                      style: t.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: kc,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    row(
                                      l.kind == ListingKind.agency
                                          ? 'Loyer mensuel'
                                          : 'Loyer mensuel (par personne)',
                                      l.rent,
                                    ),
                                    row('Caution', l.caution),
                                    row('Frais de prestation', l.serviceFee),
                                    const Divider(height: 24),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "Total à prévoir à l'entrée",
                                            style: t.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        ShaderMask(
                                          shaderCallback: (r) =>
                                              kAccentGradient.createShader(r),
                                          child: Text(
                                            fcfa(l.entryCost),
                                            style: t.titleLarge?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                        i: 1,
                      ),
                      section(
                        'Infos',
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              Icons.bed_outlined,
                              l.kind == ListingKind.request
                                  ? '${l.spots} personne(s)'
                                  : '${l.spots} place(s) disponible(s)',
                              kc,
                            ),
                            if (l.houseState != null)
                              _InfoChip(
                                Icons.verified_outlined,
                                'État : ${l.houseState!.label}',
                                const Color(0xFF16A34A),
                              ),
                          ],
                        ),
                        i: 2,
                      ),
                      if (l.description.isNotEmpty)
                        section(
                          'Description',
                          Text(
                            l.description,
                            style: t.bodyLarge?.copyWith(height: 1.4),
                          ),
                          i: 3,
                        ),
                      if (l.conditions.isNotEmpty)
                        section(
                          'Conditions',
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: kAccent.withValues(alpha: .09),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: kAccent.withValues(alpha: .25),
                              ),
                            ),
                            child: Text(
                              l.conditions,
                              style: t.bodyMedium?.copyWith(height: 1.4),
                            ),
                          ),
                          i: 4,
                        ),
                      section(
                        'Annonceur',
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: kc.withValues(alpha: .15),
                              child: Text(
                                l.ownerName.characters.first.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: kc,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.ownerName,
                                    style: t.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    l.ownerRole == UserRole.agency
                                        ? 'Agence immobilière'
                                        : 'Étudiant · publié ${ago(l.createdAt)}',
                                    style: t.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        i: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: mine
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'Ceci est votre annonce.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : unlocked != null
                    ? ContactActions(unlocked)
                    : pending != null && pending.status == PaymentStatus.pending
                    ? _PendingBar(onRefresh: s.loadAccount)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (pending != null &&
                              pending.status == PaymentStatus.rejected)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Votre précédent avis a été refusé. Vérifiez le paiement puis réessayez.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          GradientButton(
                            pulse: true,
                            icon: Icons.lock_open_rounded,
                            label:
                                'Contacter · ${fcfa(AppConfig.contactFeeFcfa)}',
                            gradient: kAccentGradient,
                            onPressed: _contact,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.text, this.color);
  final IconData icon;
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

class _PendingBar extends StatefulWidget {
  const _PendingBar({required this.onRefresh});
  final Future<void> Function() onRefresh;
  @override
  State<_PendingBar> createState() => _PendingBarState();
}

class _PendingBarState extends State<_PendingBar>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
    decoration: BoxDecoration(
      color: kAccent.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kAccent.withValues(alpha: .35)),
    ),
    child: Row(
      children: [
        RotationTransition(
          turns: _c,
          child: const Icon(Icons.hourglass_top_rounded, color: kAccent),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            "Paiement en attente de validation par l'administrateur",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        IconButton(
          tooltip: 'Actualiser',
          onPressed: widget.onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
  );
}
