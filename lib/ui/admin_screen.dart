import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import 'admin_design.dart';
import 'admin_promos.dart';
import 'admin_stats.dart';
import 'design.dart';
import 'theme.dart';
import 'widgets.dart';

/// Espace administrateur : paiements, statistiques, flyers, design.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final d = D.s;
    const labels = ['Paiements', 'Statistiques', 'Flyers', 'Design'];
    const icons = [
      Icons.fact_check_outlined,
      Icons.insights_outlined,
      Icons.campaign_outlined,
      Icons.palette_outlined,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GradientHeader(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Administration',
                style: TextStyle(
                  color: d.headerInk,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                runSpacing: 8,
                children: [
                  for (var i = 0; i < labels.length; i++)
                    DesignChip(
                      label: i == 0 && s.pendingAdminCount > 0
                          ? '${labels[i]} (${s.pendingAdminCount})'
                          : labels[i],
                      icon: icons[i],
                      selected: s.adminTab == i,
                      onTap: () {
                        s.adminTab = i;
                        s.notifyListeners_();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: switch (s.adminTab) {
            1 => const AdminStatsTab(),
            2 => const AdminPromosTab(),
            3 => const AdminDesignTab(),
            _ => const _PaymentsTab(),
          },
        ),
      ],
    );
  }
}

class _PaymentsTab extends StatefulWidget {
  const _PaymentsTab();
  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> {
  PaymentStatus _filter = PaymentStatus.pending;
  final _busy = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => AppScope.of(context).loadAccount(),
    );
  }

  Future<void> _review(PaymentNotice n, bool approve) async {
    final s = AppScope.of(context);
    setState(() => _busy.add(n.id));
    try {
      await s.review(n.id, approve: approve);
      if (mounted)
        toast(
          context,
          approve
              ? 'Validé : le contact est débloqué pour ${n.payerName}.'
              : 'Avis refusé.',
        );
    } on AppException catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy.remove(n.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final all = s.adminPayments;
    final shown = all.where((p) => p.status == _filter).toList();
    int count(PaymentStatus st) => all.where((p) => p.status == st).length;

    return RefreshIndicator(
      onRefresh: s.loadAccount,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Vérifiez la réception des 1 000 FCFA puis validez pour débloquer le contact.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                DesignChip(
                  onHeader: false,
                  label: 'En attente · ${count(PaymentStatus.pending)}',
                  selected: _filter == PaymentStatus.pending,
                  onTap: () => setState(() => _filter = PaymentStatus.pending),
                ),
                DesignChip(
                  onHeader: false,
                  label: 'Validés · ${count(PaymentStatus.approved)}',
                  selected: _filter == PaymentStatus.approved,
                  onTap: () => setState(() => _filter = PaymentStatus.approved),
                ),
                DesignChip(
                  onHeader: false,
                  label: 'Refusés · ${count(PaymentStatus.rejected)}',
                  selected: _filter == PaymentStatus.rejected,
                  onTap: () => setState(() => _filter = PaymentStatus.rejected),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: kBrand.withValues(alpha: .4),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _filter == PaymentStatus.pending
                        ? 'Aucun paiement en attente.'
                        : 'Rien ici pour le moment.',
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < shown.length; i++)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: FadeSlideIn(
                    key: ValueKey(shown[i].id),
                    index: i,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  shown[i].payerName,
                                  style: t.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Text(
                                fcfa(shown[i].amount),
                                style: t.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: kAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pour : ${shown[i].listingTitle}',
                            style: t.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _Tag(
                                Icons.account_balance_wallet_outlined,
                                shown[i].method,
                              ),
                              _Tag(Icons.phone_android, shown[i].payerPhone),
                              if (shown[i].reference.isNotEmpty)
                                _Tag(Icons.tag, 'Réf. ${shown[i].reference}'),
                              _Tag(Icons.schedule, ago(shown[i].createdAt)),
                            ],
                          ),
                          if (shown[i].status == PaymentStatus.pending) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _busy.contains(shown[i].id)
                                        ? null
                                        : () => _review(shown[i], false),
                                    icon: const Icon(Icons.close),
                                    label: const Text('Refuser'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFDC2626),
                                      minimumSize: const Size.fromHeight(48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GradientButton(
                                    label: 'Valider',
                                    icon: Icons.check,
                                    busy: _busy.contains(shown[i].id),
                                    onPressed: () => _review(shown[i], true),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: kBrand.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: kBrand),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
