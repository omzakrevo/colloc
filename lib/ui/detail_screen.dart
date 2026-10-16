import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final mine = s.user?.id == l.ownerId;

    Widget row(String k, int v, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(k, style: bold ? t.titleSmall : t.bodyMedium)),
          Text(
            v == 0 ? 'Aucune' : fcfa(v),
            style: (bold ? t.titleSmall : t.bodyMedium)?.copyWith(
              fontWeight: FontWeight.w700,
              color: bold ? kBrand : null,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.kind.label)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              if (l.kind.hasHouse)
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    children: [
                      PageView(
                        controller: _page,
                        onPageChanged: (i) => setState(() => _idx = i),
                        children: l.photos.isEmpty
                            ? [PhotoView(photo: null, kind: l.kind)]
                            : [
                                for (final p in l.photos)
                                  PhotoView(photo: p, kind: l.kind),
                              ],
                      ),
                      if (l.photos.length > 1)
                        Positioned(
                          bottom: 8,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_idx + 1}/${l.photos.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KindBadge(l.kind),
                    const SizedBox(height: 8),
                    Text(
                      l.title,
                      style: t.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 18),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${l.neighborhood.isEmpty ? '' : '${l.neighborhood}, '}${l.city}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (l.kind == ListingKind.request)
                              row('Budget maximum / mois', l.rent, bold: true)
                            else ...[
                              row(
                                l.kind == ListingKind.agency
                                    ? 'Loyer mensuel'
                                    : 'Loyer mensuel (par personne)',
                                l.rent,
                              ),
                              row('Caution', l.caution),
                              row('Frais de prestation', l.serviceFee),
                              const Divider(),
                              row(
                                "Total à prévoir à l'entrée",
                                l.entryCost,
                                bold: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.bed_outlined, size: 18),
                          label: Text(
                            l.kind == ListingKind.request
                                ? '${l.spots} personne(s)'
                                : '${l.spots} place(s) disponible(s)',
                          ),
                        ),
                        if (l.houseState != null)
                          Chip(
                            avatar: const Icon(
                              Icons.verified_outlined,
                              size: 18,
                            ),
                            label: Text('État : ${l.houseState!.label}'),
                          ),
                      ],
                    ),
                    if (l.description.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Description',
                        style: t.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(l.description),
                    ],
                    if (l.conditions.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Conditions',
                        style: t.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(l.conditions),
                    ],
                    const SizedBox(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text(l.ownerName.characters.first.toUpperCase()),
                      ),
                      title: Text(l.ownerName),
                      subtitle: Text(
                        l.ownerRole == UserRole.agency
                            ? 'Agence immobilière'
                            : 'Étudiant · publié ${ago(l.createdAt)}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: mine
                  ? const Text(
                      'Ceci est votre annonce.',
                      textAlign: TextAlign.center,
                    )
                  : unlocked != null
                  ? Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => launchUrl(
                              Uri.parse('tel:${cleanPhone(unlocked.phone)}'),
                            ),
                            icon: const Icon(Icons.call),
                            label: Text(unlocked.phone),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'WhatsApp',
                          onPressed: () => launchUrl(
                            Uri.parse(
                              'https://wa.me/${cleanPhone(unlocked.phone).replaceAll('+', '')}',
                            ),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.chat),
                        ),
                      ],
                    )
                  : FilledButton.icon(
                      onPressed: _contact,
                      icon: const Icon(Icons.lock_open),
                      label: Text(
                        'Contacter · ${fcfa(AppConfig.contactFeeFcfa)}',
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
