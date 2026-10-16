import 'package:flutter/material.dart';

import '../config.dart';
import '../state/app_state.dart';
import '../util/update_check.dart';
import 'auth_screen.dart';
import 'feed_screen.dart';
import 'profile_screen.dart';
import 'theme.dart';
import 'publish_screen.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  Future<void> _go(int i) async {
    final s = AppScope.of(context);
    if (i != 0 && s.user == null) {
      final ok = await Navigator.of(context)
          .push<bool>(MaterialPageRoute(builder: (_) => const AuthScreen()));
      if (ok != true) return;
    }
    if (mounted) setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final pages = [
      const FeedScreen(),
      if (s.user != null)
        PublishScreen(onDone: () => setState(() => _tab = 0))
      else
        const SizedBox(),
      if (s.user != null) const ProfileScreen() else const SizedBox(),
    ];
    return Scaffold(
      body: Column(
        children: [
          if (AppConfig.isDemo)
            Material(
              color: const Color(0xFFFEF3C7),
              child: const SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'MODE DÉMO · données fictives, aucun paiement réel',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          if (s.updateAvailable)
            Material(
              color: kBrand,
              child: SafeArea(
                bottom: false,
                child: ListTile(
                  dense: true,
                  textColor: Colors.white,
                  iconColor: Colors.white,
                  leading: const Icon(Icons.system_update_alt),
                  title: const Text('Une nouvelle version est disponible'),
                  trailing: TextButton(
                    onPressed: reloadApp,
                    child: const Text(
                      'Mettre à jour',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: IndexedStack(index: _tab, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _go,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Annonces'),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle, color: kAccent),
            label: 'Publier',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
