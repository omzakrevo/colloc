import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import 'detail_screen.dart';
import 'design.dart';
import 'theme.dart';
import 'widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Listing> _mine = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final s = AppScope.of(context);
    final r = await s.repo.myListings();
    await s.loadAccount();
    if (mounted) {
      setState(() {
        _mine = r;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final u = s.user!;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 16,
                16,
                24,
              ),
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: D.s.headerColors.length > 1
                          ? D.s.headerColors
                          : [D.s.headerColors.first, D.s.headerColors.first],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: D.s.border > 0
                        ? Border.all(color: D.s.borderColor, width: D.s.border)
                        : null,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: kBrand.withValues(alpha: .3),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    textColor: D.s.headerInk,
                    iconColor: D.s.headerInk,
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: kBrand,
                      child: Text(
                        u.displayName.characters.first.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    title: Text(
                      u.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      '${switch (u.role) {
                        UserRole.agency => 'Agence',
                        UserRole.admin => 'Administrateur',
                        _ => 'Étudiant',
                      }} · ${u.phone}',
                      style: TextStyle(
                        color: D.s.headerInk.withValues(alpha: .75),
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'Déconnexion',
                      icon: const Icon(Icons.logout),
                      onPressed: () async {
                        await s.signOut();
                        if (context.mounted) {
                          toast(context, 'Déconnecté');
                        }
                      },
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final c = TextEditingController(text: u.phone);
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text(
                            'Mon numéro (téléphone / WhatsApp)',
                          ),
                          content: TextField(
                            controller: c,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: '+226 70 00 00 00',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Annuler'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(100, 44),
                              ),
                              child: const Text('Enregistrer'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        try {
                          await s.updatePhone(c.text.trim());
                          if (context.mounted)
                            toast(context, 'Numéro enregistré');
                        } catch (e) {
                          if (context.mounted) toast(context, e.toString());
                        }
                      }
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                      u.phone.isEmpty
                          ? 'Ajouter mon numéro (obligatoire pour être contacté)'
                          : 'Modifier mon numéro',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Mes annonces',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_mine.isEmpty)
                  const Text("Vous n'avez pas encore publié d'annonce.")
                else
                  for (final l in _mine)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: ListTile(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(listing: l),
                            ),
                          ),
                          title: Text(
                            l.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            l.active
                                ? 'En ligne · ${ago(l.createdAt)}'
                                : 'Masquée',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: l.active,
                                onChanged: (v) async {
                                  await s.repo.setListingActive(l.id, v);
                                  await s.refresh();
                                  await _load();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await s.repo.deleteListing(l.id);
                                  await s.refresh();
                                  await _load();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                if (s.payments.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Mes paiements',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  for (final n in s.payments)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: ListTile(
                          leading: Icon(
                            switch (n.status) {
                              PaymentStatus.pending =>
                                Icons.hourglass_top_rounded,
                              PaymentStatus.approved => Icons.check_circle,
                              PaymentStatus.rejected => Icons.cancel,
                            },
                            color: switch (n.status) {
                              PaymentStatus.pending => kAccent,
                              PaymentStatus.approved => const Color(0xFF16A34A),
                              PaymentStatus.rejected => const Color(0xFFDC2626),
                            },
                          ),
                          title: Text(
                            n.listingTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${n.status.label} · ${ago(n.createdAt)}',
                          ),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Contacts débloqués',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (s.contacts.isEmpty)
                  const Text('Aucun contact pour le moment.')
                else
                  for (final c in s.contacts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.verified_user_outlined),
                          title: Text(c.name),
                          subtitle: Text(c.phone),
                          trailing: IconButton(
                            icon: const Icon(Icons.call),
                            onPressed: () => launchUrl(
                              Uri.parse('tel:${cleanPhone(c.phone)}'),
                            ),
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Colloc ${AppConfig.appVersion}${AppConfig.isDemo ? ' · mode démo' : ''}',
                    style: t.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
