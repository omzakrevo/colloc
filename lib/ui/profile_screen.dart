import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import 'detail_screen.dart';
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
    await s.loadContacts();
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
                    gradient: kBrandGradient,
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
                    textColor: Colors.white,
                    iconColor: Colors.white,
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Text(
                        u.displayName.characters.first.toUpperCase(),
                        style: const TextStyle(
                          color: kBrand,
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
                      '${u.role == UserRole.agency ? 'Agence' : 'Étudiant'} · ${u.phone}',
                      style: const TextStyle(color: Colors.white70),
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
