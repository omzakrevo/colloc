import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/repository.dart';
import '../models.dart';
import '../state/app_state.dart';
import 'design.dart';
import 'theme.dart';
import 'widgets.dart';

const _palettes = <List<int>>[
  [0xFF0F766E, 0xFF2DD4BF],
  [0xFF4338CA, 0xFF818CF8],
  [0xFFEA580C, 0xFFFBBF24],
  [0xFFDB2777, 0xFFF472B6],
  [0xFF1D4ED8, 0xFF38BDF8],
  [0xFF15803D, 0xFF86EFAC],
  [0xFF111111, 0xFF525252],
  [0xFFFEF3C7, 0xFFFDE68A],
  [0xFFD1FAE5, 0xFFA7F3D0],
  [0xFFE0E7FF, 0xFFC7D2FE],
];

/// Gestion des flyers du slider : ajouter, modifier (texte, image, lien, couleurs), activer, supprimer.
class AdminPromosTab extends StatefulWidget {
  const AdminPromosTab({super.key});
  @override
  State<AdminPromosTab> createState() => _AdminPromosTabState();
}

class _AdminPromosTabState extends State<AdminPromosTab> {
  List<Promo> _all = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final r = await AppScope.of(context).repo.allPromos();
      if (mounted)
        setState(() {
          _all = r;
          _loading = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        toast(context, e.toString());
      }
    }
  }

  Future<void> _edit([Promo? p]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: kSurface,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _PromoEditor(promo: p, nextSort: _all.length),
      ),
    );
    if (saved == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Les flyers défilent sur l'accueil. Touchez-en un pour le modifier ; les visiteurs peuvent cliquer dessus (affichage en grand + lien).",
            style: t.bodyMedium,
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: 'Ajouter un flyer',
            icon: Icons.add_photo_alternate_outlined,
            onPressed: () => _edit(),
          ),
          const SizedBox(height: 16),
          if (_loading) const Center(child: CircularProgressIndicator()),
          for (final p in _all)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: cardDecoration(radius: D.s.radius.clamp(6, 20)),
                child: Column(
                  children: [
                    SizedBox(
                      height: 120,
                      child: Opacity(
                        opacity: p.active ? 1 : .45,
                        child: PromoSlide(p, interactive: false),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Switch(
                          value: p.active,
                          onChanged: (v) async {
                            try {
                              await s.savePromo(
                                PromoDraft(
                                  id: p.id,
                                  title: p.title,
                                  subtitle: p.subtitle,
                                  linkUrl: p.linkUrl,
                                  imageUrl: p.imageUrl,
                                  imageBytes: p.imageBytes,
                                  colorA: p.colorA,
                                  colorB: p.colorB,
                                  sponsor: p.sponsor,
                                  active: v,
                                  sort: p.sort,
                                ),
                              );
                              await _load();
                            } catch (e) {
                              if (context.mounted) toast(context, e.toString());
                            }
                          },
                        ),
                        Text(
                          p.active ? 'Affiché' : 'Masqué',
                          style: t.bodySmall,
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _edit(p),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Modifier'),
                        ),
                        IconButton(
                          tooltip: 'Supprimer',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFDC2626),
                          ),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Supprimer ce flyer ?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text(
                                      'Supprimer',
                                      style: TextStyle(
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              try {
                                await s.deletePromo(p.id);
                                await _load();
                              } catch (e) {
                                if (context.mounted)
                                  toast(context, e.toString());
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PromoEditor extends StatefulWidget {
  const _PromoEditor({this.promo, required this.nextSort});
  final Promo? promo;
  final int nextSort;
  @override
  State<_PromoEditor> createState() => _PromoEditorState();
}

class _PromoEditorState extends State<_PromoEditor> {
  late final _title = TextEditingController(text: widget.promo?.title ?? '');
  late final _sub = TextEditingController(text: widget.promo?.subtitle ?? '');
  late final _link = TextEditingController(text: widget.promo?.linkUrl ?? '');
  late final _sort = TextEditingController(
    text: '${widget.promo?.sort ?? widget.nextSort}',
  );
  late int _a = widget.promo?.colorA ?? _palettes[0][0];
  late int _b = widget.promo?.colorB ?? _palettes[0][1];
  late bool _sponsor = widget.promo?.sponsor ?? false;
  late bool _active = widget.promo?.active ?? true;
  Uint8List? _bytes;
  String? _imageUrl;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.promo?.imageUrl;
    _bytes = widget.promo?.imageBytes;
  }

  @override
  void dispose() {
    for (final c in [_title, _sub, _link, _sort]) {
      c.dispose();
    }
    super.dispose();
  }

  Promo get _preview => Promo(
    id: 'preview',
    title: _title.text,
    subtitle: _sub.text,
    imageBytes: _bytes,
    imageUrl: _imageUrl,
    colorA: _a,
    colorB: _b,
    sponsor: _sponsor,
  );

  Future<void> _pick() async {
    final f = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (f == null) return;
    final b = await f.readAsBytes();
    if (mounted) setState(() => _bytes = b);
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty && !_preview.hasImage) {
      setState(() => _error = 'Ajoutez un titre ou une image.');
      return;
    }
    final link = _link.text.trim();
    if (link.isNotEmpty && !link.startsWith('http')) {
      setState(() => _error = 'Le lien doit commencer par http:// ou https://');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.of(context).savePromo(
        PromoDraft(
          id: widget.promo?.id,
          title: _title.text.trim(),
          subtitle: _sub.text.trim(),
          linkUrl: link,
          imageBytes: _bytes,
          imageUrl: _imageUrl,
          colorA: _a,
          colorB: _b,
          sponsor: _sponsor,
          active: _active,
          sort: int.tryParse(_sort.text.trim()) ?? 0,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on AppException catch (e) {
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = 'Enregistrement impossible.';
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
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.promo == null ? 'Nouveau flyer' : 'Modifier le flyer',
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: PromoSlide(_preview, interactive: false),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pick,
                        icon: const Icon(Icons.image_outlined),
                        label: Text(
                          _preview.hasImage
                              ? "Changer l'image"
                              : 'Ajouter une image (flyer)',
                        ),
                      ),
                    ),
                    if (_preview.hasImage)
                      IconButton(
                        tooltip: "Retirer l'image",
                        onPressed: () => setState(() {
                          _bytes = null;
                          _imageUrl = null;
                        }),
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _title,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Titre'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _sub,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Sous-titre'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _link,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Lien au clic (facultatif)',
                    hintText: 'https://…',
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Couleurs (si pas d\'image)',
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final p in _palettes)
                      GestureDetector(
                        onTap: () => setState(() {
                          _a = p[0];
                          _b = p[1];
                        }),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(p[0]), Color(p[1])],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _a == p[0] && _b == p[1]
                                  ? D.s.ink
                                  : Colors.black12,
                              width: _a == p[0] && _b == p[1] ? 3 : 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _sponsor,
                  onChanged: (v) => setState(() => _sponsor = v),
                  title: const Text('Afficher « Publicité »'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  title: const Text('Visible sur le site'),
                ),
                TextField(
                  controller: _sort,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Ordre d'affichage (0 = en premier)",
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                GradientButton(
                  label: 'Enregistrer',
                  icon: Icons.check,
                  busy: _busy,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
