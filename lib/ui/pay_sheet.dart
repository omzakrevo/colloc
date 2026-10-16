import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../data/repository.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import 'theme.dart';
import 'widgets.dart';

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

/// Paiement manuel : l'utilisateur envoie 1 000 FCFA en Mobile Money, émet un avis,
/// puis l'administrateur valide => le numéro est débloqué.
class _PaySheet extends StatefulWidget {
  const _PaySheet({required this.listing});
  final Listing listing;
  @override
  State<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<_PaySheet> {
  String? _method;
  late final _phone = TextEditingController(
    text: AppScope.of(context).user?.phone ?? '',
  );
  final _ref = TextEditingController();
  bool _busy = false, _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => AppScope.of(context).loadPaymentMethods(),
    );
  }

  @override
  void dispose() {
    _phone.dispose();
    _ref.dispose();
    super.dispose();
  }

  Future<void> _send(PaymentMethodInfo m) async {
    if (_phone.text.trim().length < 8) {
      setState(() => _error = 'Entrez le numéro avec lequel vous avez payé.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.of(context).submitPayment(
        widget.listing.id,
        m.label,
        _phone.text.trim(),
        _ref.text.trim(),
      );
      if (mounted) {
        setState(() {
          _busy = false;
          _sent = true;
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
        _error = "Envoi impossible. Réessayez.";
      });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
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
              child: _sent ? _sentView(context) : _formView(context),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _sentView(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      key: const ValueKey('sent'),
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
              gradient: kAccentGradient,
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: Colors.white,
              size: 46,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Avis de paiement envoyé',
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          "L'administrateur vérifie votre paiement. Dès qu'il est validé, le numéro de ${widget.listing.ownerName} s'affiche sur l'annonce et vous pouvez le contacter directement.",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        GradientButton(
          label: 'Compris',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _formView(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = AppScope.of(context);
    final methods = s.paymentMethods;
    final sel =
        methods.where((m) => m.id == _method).firstOrNull ??
        (methods.isEmpty ? null : methods.first);

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
        _StepTitle(
          '1',
          'Envoyez ${fcfa(AppConfig.contactFeeFcfa)} par Mobile Money',
        ),
        const SizedBox(height: 10),
        if (methods.isEmpty)
          const Text('Moyens de paiement indisponibles pour le moment.')
        else
          for (final m in methods)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: _busy ? null : () => setState(() => _method = m.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sel?.id == m.id
                        ? kBrand.withValues(alpha: .07)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sel?.id == m.id ? kBrand : Colors.grey.shade300,
                      width: sel?.id == m.id ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        sel?.id == m.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: sel?.id == m.id ? kBrand : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              m.number,
                              style: t.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: kBrand,
                              ),
                            ),
                            if (m.holder.isNotEmpty)
                              Text(m.holder, style: t.bodySmall),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copier le numéro',
                        icon: const Icon(Icons.copy_rounded),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: m.number),
                          );
                          if (context.mounted) toast(context, 'Numéro copié');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        const SizedBox(height: 12),
        _StepTitle('2', 'Confirmez votre paiement'),
        const SizedBox(height: 10),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Numéro avec lequel vous avez payé',
            prefixIcon: Icon(Icons.phone_android),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _ref,
          decoration: const InputDecoration(
            labelText: 'Référence de la transaction (facultatif)',
            prefixIcon: Icon(Icons.tag),
          ),
        ),
        if (AppConfig.isDemo)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Mode démo : aucun argent réel. Connectez-vous ensuite en « Admin » pour valider.",
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
          label: "J'ai payé · envoyer l'avis",
          icon: Icons.send_rounded,
          busy: _busy,
          onPressed: sel == null ? null : () => _send(sel),
        ),
      ],
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle(this.n, this.text);
  final String n, text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 12,
        backgroundColor: kAccent,
        child: Text(
          n,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}
