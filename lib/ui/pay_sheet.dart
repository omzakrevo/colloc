import 'package:flutter/material.dart';

import '../config.dart';
import '../data/repository.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import 'theme.dart';
import 'widgets.dart';

const _methods = {
  'wave': 'Wave',
  'orange': 'Orange Money',
  'mtn': 'MTN MoMo',
  'moov': 'Moov Money',
};

Future<void> showPaySheet(BuildContext context, Listing l) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _PaySheet(listing: l),
      ),
    );

class _PaySheet extends StatefulWidget {
  const _PaySheet({required this.listing});
  final Listing listing;
  @override
  State<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<_PaySheet> {
  String _method = 'wave';
  late final _phone = TextEditingController(
    text: AppScope.of(context).user?.phone ?? '',
  );
  bool _busy = false;
  String? _error;

  Future<void> _pay() async {
    if (_phone.text.trim().length < 8) {
      setState(() => _error = 'Entrez le numéro qui paie.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final c = await AppScope.of(context)
          .pay(widget.listing.id, _method, _phone.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop();
      toast(context, 'Contact débloqué : ${c.name}');
    } on AppException catch (e) {
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _busy = false;
        _error = 'Paiement impossible. Réessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Obtenir le contact',
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pour joindre ${widget.listing.ownerName}, la mise en contact coûte ${fcfa(AppConfig.contactFeeFcfa)} (une seule fois pour cette annonce).',
                ),
                const SizedBox(height: 16),
                Text('Payer avec', style: t.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in _methods.entries)
                      ChoiceChip(
                        label: Text(m.value),
                        selected: _method == m.key,
                        onSelected: _busy
                            ? null
                            : (_) => setState(() => _method = m.key),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Numéro Mobile Money',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                ),
                if (AppConfig.isDemo)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Mode démo : aucun argent n\'est débité.',
                      style: t.bodySmall?.copyWith(
                        color: kindColor(ListingKind.request),
                      ),
                    ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _pay,
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text('Payer ${fcfa(AppConfig.contactFeeFcfa)}'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
