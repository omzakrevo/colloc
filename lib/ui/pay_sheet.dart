import 'package:flutter/material.dart';

import '../config.dart';
import '../data/repository.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import 'theme.dart';
import 'widgets.dart';

const _methods = {
  'wave': ('Wave', Color(0xFF1DC8FF)),
  'orange': ('Orange Money', Color(0xFFFF7900)),
  'mtn': ('MTN MoMo', Color(0xFFFFC800)),
  'moov': ('Moov Money', Color(0xFF0077C8)),
};

Future<void> showPaySheet(BuildContext context, Listing l) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
  UnlockedContact? _done;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

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
      if (mounted) {
        setState(() {
          _busy = false;
          _done = c;
        });
      }
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
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: _done != null
                    ? _success(context, _done!)
                    : _form(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _success(BuildContext context, UnlockedContact c) {
    final t = Theme.of(context).textTheme;
    return Column(
      key: const ValueKey('ok'),
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: kBrandGradient,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 52,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Contact débloqué !',
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(c.name, style: t.bodyLarge),
        const SizedBox(height: 18),
        ContactActions(c),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget _form(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Obtenir le contact',
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Pour joindre ${widget.listing.ownerName}, la mise en contact coûte ${fcfa(AppConfig.contactFeeFcfa)} (une seule fois pour cette annonce).',
        ),
        const SizedBox(height: 18),
        Text(
          'Payer avec',
          style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final m in _methods.entries)
              GestureDetector(
                onTap: _busy ? null : () => setState(() => _method = m.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: _method == m.key
                        ? m.value.$2.withValues(alpha: .14)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _method == m.key
                          ? m.value.$2
                          : Colors.grey.shade300,
                      width: _method == m.key ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(radius: 6, backgroundColor: m.value.$2),
                      const SizedBox(width: 8),
                      Text(
                        m.value.$1,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
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
              "Mode démo : aucun argent n'est débité.",
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
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 18),
        GradientButton(
          label: 'Payer ${fcfa(AppConfig.contactFeeFcfa)}',
          icon: Icons.lock_outline,
          busy: _busy,
          onPressed: _pay,
        ),
      ],
    );
  }
}
