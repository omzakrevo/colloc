import 'package:flutter/material.dart';

import '../config.dart';
import '../state/app_state.dart';
import '../util/update_check.dart';
import 'admin_screen.dart';
import 'auth_screen.dart';
import 'feed_screen.dart';
import 'profile_screen.dart';
import 'publish_screen.dart';
import 'theme.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

enum _Id { feed, publish, admin, profile }

class _ShellState extends State<Shell> {
  // l'onglet courant vit dans AppState : il survit à la reconstruction de l'interface quand l'admin change de design
  _Id get _tab => _Id.values.byName(AppScope.of(context).shellTab);
  set _tab(_Id id) {
    final st = AppScope.of(context);
    st.shellTab = id.name;
    st.track(
      'view',
      screen: const {
        _Id.feed: 'accueil',
        _Id.publish: 'publier',
        _Id.admin: 'admin',
        _Id.profile: 'profil',
      }[id],
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).track('view', screen: 'accueil');
    });
  }

  Future<void> _go(_Id id) async {
    final s = AppScope.of(context);
    if (id != _Id.feed && s.user == null) {
      final ok = await Navigator.of(context)
          .push<bool>(MaterialPageRoute(builder: (_) => const AuthScreen()));
      if (ok != true) return;
    }
    if (mounted) setState(() => _tab = id);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    s.device = MediaQuery.of(context).size.width < 700 ? 'mobile' : 'desktop';
    final admin = s.user?.isAdmin == true;
    final ids = [_Id.feed, if (admin) _Id.admin else _Id.publish, _Id.profile];
    final current = ids.contains(_tab) ? _tab : _Id.feed;

    Widget page(_Id id) => switch (id) {
      _Id.feed => const FeedScreen(),
      _Id.publish =>
        s.user != null && !admin
            ? PublishScreen(onDone: () => setState(() => _tab = _Id.feed))
            : const SizedBox(),
      _Id.admin => admin ? const AdminScreen() : const SizedBox(),
      _Id.profile => s.user != null ? const ProfileScreen() : const SizedBox(),
    };

    NavigationDestination dest(_Id id) => switch (id) {
      _Id.feed => const NavigationDestination(
        icon: Icon(Icons.search),
        label: 'Annonces',
      ),
      _Id.publish => NavigationDestination(
        icon: Icon(Icons.add_circle_outline),
        selectedIcon: Icon(Icons.add_circle, color: kAccent),
        label: 'Publier',
      ),
      _Id.admin => NavigationDestination(
        icon: Badge(
          isLabelVisible: s.pendingAdminCount > 0,
          label: Text('${s.pendingAdminCount}'),
          child: const Icon(Icons.admin_panel_settings_outlined),
        ),
        selectedIcon: Icon(Icons.admin_panel_settings, color: kAccent),
        label: 'Admin',
      ),
      _Id.profile => const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    };

    return Scaffold(
      body: Column(
        children: [
          if (AppConfig.isDemo)
            const Material(
              color: Color(0xFFFEF3C7),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'MODE DÉMO · données fictives, aucun paiement réel',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B2F0B),
                    ),
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
            child: MediaQuery.removePadding(
              context: context,
              removeTop: AppConfig.isDemo || s.updateAvailable,
              child: IndexedStack(
                index: ids.indexOf(current),
                children: [for (final id in ids) page(id)],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: ids.indexOf(current),
        onDestinationSelected: (i) => _go(ids[i]),
        destinations: [for (final id in ids) dest(id)],
      ),
    );
  }
}
