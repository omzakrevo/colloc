import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../state/app_state.dart';
import 'design.dart';
import 'widgets.dart';

/// Choix du design du site (5 designs très différents) et de ses couleurs. L'application s'applique à tous les visiteurs.
class AdminDesignTab extends StatefulWidget {
  const AdminDesignTab({super.key});
  @override
  State<AdminDesignTab> createState() => _AdminDesignTabState();
}

class _AdminDesignTabState extends State<AdminDesignTab> {
  late ThemeSettings _draft = AppScope.of(context).theme;
  bool _busy = false;

  Future<void> _apply() async {
    final s = AppScope.of(context);
    setState(() => _busy = true);
    try {
      await s.saveTheme(
        _draft,
      ); // reconstruit toute l'interface avec le nouveau design
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        toast(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        toast(context, 'Enregistrement impossible.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final spec = buildDesign(_draft);
    final changed =
        _draft.design != s.theme.design ||
        _draft.primary != s.theme.primary ||
        _draft.accent != s.theme.accent;

    Widget swatches(
      String title,
      int? value,
      int base,
      ValueChanged<int?> onPick,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            GestureDetector(
              onTap: () => onPick(null),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(base),
                  border: Border.all(
                    color: value == null ? D.s.ink : Colors.black12,
                    width: value == null ? 3 : 1,
                  ),
                ),
                child: Icon(
                  Icons.restart_alt,
                  size: 18,
                  color: onColor(Color(base)),
                ),
              ),
            ),
            for (final c in kSwatches)
              GestureDetector(
                onTap: () => onPick(c),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(c),
                    border: Border.all(
                      color: value == c ? D.s.ink : Colors.black12,
                      width: value == c ? 3 : 1,
                    ),
                  ),
                  child: value == c
                      ? Icon(Icons.check, size: 18, color: onColor(Color(c)))
                      : null,
                ),
              ),
          ],
        ),
      ],
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "Choisissez le design du site. Il s'applique à tous les visiteurs (web et mobile) dès que vous cliquez sur « Appliquer ».",
          style: t.bodyMedium,
        ),
        const SizedBox(height: 14),
        for (final id in DesignId.values)
          _DesignTile(
            id: id,
            settings: ThemeSettings(
              design: id,
              primary: _draft.primary,
              accent: _draft.accent,
            ),
            selected: _draft.design == id,
            onTap: () => setState(() => _draft = _draft.copyWith(design: id)),
          ),
        const SizedBox(height: 10),
        swatches(
          'Couleur principale',
          _draft.primary,
          buildDesign(ThemeSettings(design: _draft.design)).primary.toARGB32(),
          (c) => setState(
            () => _draft = ThemeSettings(
              design: _draft.design,
              primary: c,
              accent: _draft.accent,
            ),
          ),
        ),
        const SizedBox(height: 14),
        swatches(
          "Couleur d'accent",
          _draft.accent,
          buildDesign(ThemeSettings(design: _draft.design)).accent.toARGB32(),
          (c) => setState(
            () => _draft = ThemeSettings(
              design: _draft.design,
              primary: _draft.primary,
              accent: c,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Aperçu',
          style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        _MiniPreview(spec),
        const SizedBox(height: 16),
        GradientButton(
          label: changed ? 'Appliquer à tout le site' : 'Design actuel',
          icon: Icons.palette_outlined,
          busy: _busy,
          onPressed: changed ? _apply : null,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _DesignTile extends StatelessWidget {
  const _DesignTile({
    required this.id,
    required this.settings,
    required this.selected,
    required this.onTap,
  });
  final DesignId id;
  final ThemeSettings settings;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final sp = buildDesign(settings);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: D.s.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? sp.primary : D.s.ink.withValues(alpha: .15),
              width: selected ? 3 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 74,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: sp.headerColors.length > 1
                        ? sp.headerColors
                        : [sp.headerColors.first, sp.headerColors.first],
                  ),
                  color: sp.bg,
                  borderRadius: BorderRadius.circular(
                    sp.id == DesignId.minimal ? 4 : 12,
                  ),
                  border: Border.all(
                    color: sp.id == DesignId.pop ? sp.ink : Colors.black12,
                    width: sp.id == DesignId.pop ? 3 : 1,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 38,
                    height: 14,
                    decoration: BoxDecoration(
                      color: sp.primary,
                      borderRadius: BorderRadius.circular(
                        sp.id == DesignId.minimal ? 2 : 8,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sp.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      sp.tagline,
                      style: TextStyle(fontSize: 12, color: D.s.muted),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? sp.primary : D.s.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Maquette fidèle du design sélectionné (en-tête, carte, bouton), sans changer le design réel.
class _MiniPreview extends StatelessWidget {
  const _MiniPreview(this.d);
  final DesignSpec d;
  @override
  Widget build(BuildContext context) {
    final flat = d.headerStyle == HeaderStyle.flat,
        pop = d.headerStyle == HeaderStyle.pop;
    final btn = LinearGradient(
      colors: d.buttonColors.length > 1
          ? d.buttonColors
          : [d.buttonColors.first, d.buttonColors.first],
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: d.bg,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                gradient: flat || pop
                    ? null
                    : LinearGradient(colors: d.headerColors),
                color: flat ? d.surface : (pop ? d.headerColors.first : null),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(d.headerRadius.clamp(0, 28)),
                ),
                border: flat
                    ? Border(bottom: BorderSide(color: d.borderColor))
                    : (pop
                          ? Border(bottom: BorderSide(color: d.ink, width: 3))
                          : null),
              ),
              child: Column(
                crossAxisAlignment: d.headerStyle == HeaderStyle.warm
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    'Colloc',
                    style: TextStyle(
                      color: d.headerInk,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Trouve ta coloc, sans prise de tête.',
                    style: TextStyle(
                      color: d.headerInk,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _Pill('Tout', true, d),
                      _Pill('Colocations', false, d),
                      _Pill('Agences', false, d),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Container(
                    height: 76,
                    decoration: BoxDecoration(
                      color: d.surface,
                      borderRadius: BorderRadius.circular(
                        d.radius.clamp(4, 22),
                      ),
                      border: d.border > 0
                          ? Border.all(color: d.borderColor, width: d.border)
                          : null,
                      boxShadow: d.offsetShadow
                          ? [
                              BoxShadow(
                                color: d.ink,
                                offset: const Offset(4, 4),
                                blurRadius: 0,
                              ),
                            ]
                          : (d.id == DesignId.minimal
                                ? null
                                : [
                                    BoxShadow(
                                      color: d.primary.withValues(alpha: .18),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 84,
                          decoration: BoxDecoration(
                            color: d.primary,
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(d.radius.clamp(4, 22)),
                            ),
                          ),
                          child: Icon(
                            Icons.home_work_outlined,
                            color: onColor(d.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '2 chambres libres',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: d.ink,
                                ),
                              ),
                              Text(
                                'Ouagadougou · 30 000 FCFA/mois',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: d.ink.withValues(alpha: .65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 46,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: btn,
                      borderRadius: BorderRadius.circular(
                        d.id == DesignId.minimal ? 6 : 14,
                      ),
                      border: pop ? Border.all(color: d.ink, width: 3) : null,
                      boxShadow: d.offsetShadow
                          ? [
                              BoxShadow(
                                color: d.ink,
                                offset: const Offset(3, 3),
                                blurRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        'Contacter · 1 000 FCFA',
                        style: TextStyle(
                          color: onColor(
                            mix(d.buttonColors.first, d.buttonColors.last, .5),
                          ),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.sel, this.d);
  final String label;
  final bool sel;
  final DesignSpec d;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: sel ? d.chipSel : d.chipUnsel,
      borderRadius: BorderRadius.circular(
        d.id == DesignId.minimal ? 5 : (d.id == DesignId.pop ? 8 : 20),
      ),
      border: Border.all(
        color: d.chipBorder,
        width: d.id == DesignId.pop ? 2 : 1,
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: sel ? d.chipSelInk : d.chipUnselInk,
      ),
    ),
  );
}
