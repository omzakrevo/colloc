import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import 'theme.dart';
import 'widgets.dart';

/// Espace administrateur : valider ou refuser les avis de paiement.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
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
      if (mounted) {
        toast(
          context,
          approve
              ? 'Validé : le contact est débloqué pour ${n.payerName}.'
              : 'Avis refusé.',
        );
      }
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

    Widget pill(String label, PaymentStatus st) {
      final sel = _filter == st;
      final n = all.where((p) => p.status == st).length;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => setState(() => _filter = st),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: sel ? kBrand : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: sel ? kBrand : Colors.grey.shade300),
            ),
            child: Text(
              '$label · $n',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: sel ? Colors.white : kInk,
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: s.loadAccount,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paiements',
                    style: TextStyle(
                      color: kInk,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vérifiez la réception des 1 000 FCFA puis validez pour débloquer le contact.',
                    style: TextStyle(color: kInk.withValues(alpha: .75)),
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        pill('En attente', PaymentStatus.pending),
                        pill('Validés', PaymentStatus.approved),
                        pill('Refusés', PaymentStatus.rejected),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (shown.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.separated(
                itemCount: shown.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final n = shown[i];
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: FadeSlideIn(
                        key: ValueKey(n.id),
                        index: i,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: kBrand.withValues(alpha: .10),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.payerName,
                                      style: t.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    fcfa(n.amount),
                                    style: t.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: kAccent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pour : ${n.listingTitle}',
                                style: t.bodyMedium,
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _Tag(
                                    Icons.account_balance_wallet_outlined,
                                    n.method,
                                  ),
                                  _Tag(Icons.phone_android, n.payerPhone),
                                  if (n.reference.isNotEmpty)
                                    _Tag(Icons.tag, 'Réf. ${n.reference}'),
                                  _Tag(Icons.schedule, ago(n.createdAt)),
                                ],
                              ),
                              if (n.status == PaymentStatus.pending) ...[
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _busy.contains(n.id)
                                            ? null
                                            : () => _review(n, false),
                                        icon: const Icon(Icons.close),
                                        label: const Text('Refuser'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFFDC2626,
                                          ),
                                          minimumSize: const Size.fromHeight(
                                            48,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: GradientButton(
                                        label: 'Valider',
                                        icon: Icons.check,
                                        busy: _busy.contains(n.id),
                                        onPressed: () => _review(n, true),
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
                  );
                },
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
      color: kBrand.withValues(alpha: .08),
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
