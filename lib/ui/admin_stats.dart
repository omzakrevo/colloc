import 'package:flutter/material.dart';

import '../config.dart';
import '../data/repository.dart';
import '../models.dart';
import '../state/app_state.dart';
import 'design.dart';
import 'theme.dart';
import 'widgets.dart';

/// Tableau de bord : visiteurs, comportement, entonnoir de conversion, classements.
class AdminStatsTab extends StatefulWidget {
  const AdminStatsTab({super.key});
  @override
  State<AdminStatsTab> createState() => _AdminStatsTabState();
}

class _AdminStatsTabState extends State<AdminStatsTab> {
  int _days = 14;
  Stats? _stats;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final s = AppScope.of(context);
    setState(() => _loading = true);
    try {
      final r = await s.repo.adminStats(_days);
      if (mounted)
        setState(() {
          _stats = r;
          _error = null;
          _loading = false;
        });
    } on AppException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'Statistiques indisponibles.';
          _loading = false;
        });
    }
  }

  String _pct(int a, int b) => b == 0 ? '0 %' : '${(100 * a / b).round()} %';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final st = _stats;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text('Période :', style: t.bodyMedium),
              const SizedBox(width: 10),
              for (final d in [7, 14, 30])
                DesignChip(
                  onHeader: false,
                  label: '$d jours',
                  selected: _days == d,
                  onTap: () {
                    _days = d;
                    _load();
                  },
                ),
            ],
          ),
          if (AppConfig.isDemo)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Mode démo : l'historique est fictif. En production, ce sont les vrais visiteurs (votre propre navigation d'administrateur n'est pas comptée).",
                style: TextStyle(fontSize: 12, color: Color(0xFF3B2F0B)),
              ),
            ),
          const SizedBox(height: 14),
          if (_loading && st == null)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(_error!)),
            )
          else if (st != null) ...[
            // ── visiteurs
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Kpi(
                  Icons.today_outlined,
                  "Visiteurs aujourd'hui",
                  '${st.visitorsToday}',
                  kBrand,
                ),
                _Kpi(
                  Icons.date_range_outlined,
                  'Visiteurs 7 jours',
                  '${st.visitors7}',
                  kIndigo,
                ),
                _Kpi(
                  Icons.calendar_month_outlined,
                  'Visiteurs 30 jours',
                  '${st.visitors30}',
                  kAccent,
                ),
                _Kpi(
                  Icons.visibility_outlined,
                  'Pages vues',
                  '${st.pageViews}',
                  kBrand,
                ),
                _Kpi(
                  Icons.home_work_outlined,
                  'Annonces consultées',
                  '${st.listingViews}',
                  kIndigo,
                ),
                _Kpi(
                  Icons.touch_app_outlined,
                  'Clics « Contacter »',
                  '${st.contactClicks}',
                  kAccent,
                ),
                _Kpi(
                  Icons.receipt_long_outlined,
                  'Avis de paiement',
                  '${st.paymentNotices}',
                  kBrand,
                ),
                _Kpi(
                  Icons.verified_outlined,
                  'Paiements validés',
                  '${st.approved}',
                  const Color(0xFF16A34A),
                ),
                _Kpi(
                  Icons.person_add_alt_outlined,
                  'Inscriptions',
                  '${st.signups}',
                  kIndigo,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const SectionTitle('Visiteurs par jour'),
            const SizedBox(height: 10),
            _Card(
              child: SizedBox(
                height: 190,
                child: CustomPaint(
                  painter: _DailyChart(st.daily, kBrand, kAccent, D.s.ink),
                  size: Size.infinite,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Container(width: 10, height: 10, color: kBrand),
                  const SizedBox(width: 6),
                  Text('Visiteurs', style: t.bodySmall),
                  const SizedBox(width: 14),
                  Container(width: 10, height: 3, color: kAccent),
                  const SizedBox(width: 6),
                  Text('Pages vues', style: t.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 22),
            // ── comportement
            const SectionTitle('Comportement des visiteurs'),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                children: [
                  _Funnel(
                    'Visiteurs',
                    st.funnelVisitors,
                    st.funnelVisitors,
                    kBrand,
                  ),
                  _Funnel(
                    'Ont consulté une annonce',
                    st.funnelListing,
                    st.funnelVisitors,
                    kIndigo,
                  ),
                  _Funnel(
                    'Ont cliqué sur « Contacter »',
                    st.funnelContact,
                    st.funnelVisitors,
                    kAccent,
                  ),
                  _Funnel(
                    'Ont émis un avis de paiement',
                    st.funnelNotice,
                    st.funnelVisitors,
                    const Color(0xFF16A34A),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Insight(
                    Icons.timelapse,
                    '${st.screensPerSession.toStringAsFixed(1)} pages par session',
                    '${st.sessions} sessions sur la période',
                  ),
                  _Insight(
                    Icons.search,
                    '${_pct(st.funnelListing, st.funnelVisitors)} consultent au moins une annonce',
                    "Ceux qui n'en ouvrent aucune partent depuis l'accueil",
                  ),
                  _Insight(
                    Icons.touch_app,
                    '${_pct(st.funnelContact, st.funnelListing)} des lecteurs cliquent sur « Contacter »',
                    'Parmi ceux qui ont consulté une annonce',
                  ),
                  _Insight(
                    Icons.payments_outlined,
                    '${_pct(st.funnelNotice, st.funnelContact)} vont jusqu\'à l\'avis de paiement',
                    'Parmi ceux qui ont cliqué sur « Contacter »',
                  ),
                  _Insight(
                    Icons.manage_search,
                    '${st.searches} recherches',
                    'Mots-clés les plus tapés ci-dessous',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionTitle('Annonces les plus vues'),
            const SizedBox(height: 10),
            _RankCard(st.topListings, 'vues', 'contacts'),
            const SizedBox(height: 22),
            const SectionTitle('Villes recherchées'),
            const SizedBox(height: 10),
            _RankCard(st.topCities, 'filtres', null),
            const SizedBox(height: 22),
            const SectionTitle('Recherches'),
            const SizedBox(height: 10),
            _RankCard(st.topSearches, 'fois', null),
            const SizedBox(height: 22),
            const SectionTitle('Flyers'),
            const SizedBox(height: 10),
            _RankCard(st.topPromos, 'vues', 'clics', ctr: true),
            const SizedBox(height: 22),
            const SectionTitle('Appareils'),
            const SizedBox(height: 10),
            _RankCard(st.devices, 'visiteurs', null),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: cardDecoration(radius: D.s.radius.clamp(6, 20)),
    child: child,
  );
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.icon, this.label, this.value, this.color);
  final IconData icon;
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SizedBox(
      width: 168,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: cardDecoration(radius: D.s.radius.clamp(6, 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(label, style: t.bodySmall?.copyWith(color: D.s.muted)),
          ],
        ),
      ),
    );
  }
}

class _Funnel extends StatelessWidget {
  const _Funnel(this.label, this.value, this.total, this.color);
  final String label;
  final int value, total;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final r = total == 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '$value  ·  ${(r * 100).round()} %',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: r),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 10,
                color: color,
                backgroundColor: color.withValues(alpha: .15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Insight extends StatelessWidget {
  const _Insight(this.icon, this.title, this.sub);
  final IconData icon;
  final String title, sub;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: kBrand),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(sub, style: TextStyle(fontSize: 12, color: D.s.muted)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RankCard extends StatelessWidget {
  const _RankCard(this.items, this.aLabel, this.bLabel, {this.ctr = false});
  final List<RankItem> items;
  final String aLabel;
  final String? bLabel;
  final bool ctr;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty)
      return _Card(
        child: Text(
          'Pas encore de données.',
          style: TextStyle(color: D.s.muted),
        ),
      );
    final max = items.map((e) => e.a).reduce((a, b) => a > b ? a : b);
    return _Card(
      child: Column(
        children: [
          for (final e in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        '${e.a} $aLabel${bLabel != null ? '  ·  ${e.b} $bLabel' : ''}${ctr && e.a > 0 ? '  ·  ${(100 * e.b / e.a).toStringAsFixed(1)} %' : ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: max == 0 ? 0 : e.a / max,
                      minHeight: 6,
                      color: kBrand,
                      backgroundColor: kBrand.withValues(alpha: .12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Histogramme des visiteurs par jour + courbe des pages vues.
class _DailyChart extends CustomPainter {
  _DailyChart(this.days, this.bar, this.line, this.ink);
  final List<DayStat> days;
  final Color bar, line, ink;

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;
    const left = 28.0, bottom = 22.0, top = 8.0;
    final w = size.width - left, h = size.height - bottom - top;
    final maxV = days
        .map((d) => d.views > d.visitors ? d.views : d.visitors)
        .fold<int>(1, (a, b) => a > b ? a : b);
    final grid = Paint()
      ..color = ink.withValues(alpha: .10)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = top + h * i / 3;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), grid);
      final tp = TextPainter(
        text: TextSpan(
          text: '${(maxV * (3 - i) / 3).round()}',
          style: TextStyle(fontSize: 9, color: ink.withValues(alpha: .6)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
    final slot = w / days.length;
    final bw = (slot * .55).clamp(3.0, 22.0);
    final path = Path();
    for (var i = 0; i < days.length; i++) {
      final x = left + slot * i + slot / 2;
      final bh = h * days[i].visitors / maxV;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - bw / 2, top + h - bh, bw, bh),
          const Radius.circular(3),
        ),
        Paint()..color = bar,
      );
      final vy = top + h - h * days[i].views / maxV;
      if (i == 0) {
        path.moveTo(x, vy);
      } else {
        path.lineTo(x, vy);
      }
      final step = days.length > 14 ? 5 : (days.length > 7 ? 2 : 1);
      if (i % step == 0 || i == days.length - 1) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${days[i].day.day}/${days[i].day.month}',
            style: TextStyle(fontSize: 9, color: ink.withValues(alpha: .6)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, size.height - tp.height));
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_DailyChart old) =>
      old.days != days || old.bar != bar || old.line != line;
}
