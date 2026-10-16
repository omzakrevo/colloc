import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/repository.dart';
import '../models.dart';
import '../state/app_state.dart';
import 'theme.dart';
import 'widgets.dart';

class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final _form = GlobalKey<FormState>();
  ListingKind? _kind;
  final _title = TextEditingController(),
      _city = TextEditingController(),
      _hood = TextEditingController();
  final _desc = TextEditingController(), _cond = TextEditingController();
  final _rent = TextEditingController(),
      _caution = TextEditingController(),
      _fee = TextEditingController(),
      _spots = TextEditingController(text: '1');
  HouseState _state = HouseState.bon;
  final _photos = <Uint8List>[];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _title,
      _city,
      _hood,
      _desc,
      _cond,
      _rent,
      _caution,
      _fee,
      _spots,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int _n(TextEditingController c) =>
      int.tryParse(c.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  Future<void> _pick() async {
    final files = await ImagePicker().pickMultiImage(
      imageQuality: 75,
      maxWidth: 1600,
    );
    final bytes = [for (final f in files) await f.readAsBytes()];
    if (mounted) setState(() => _photos.addAll(bytes.take(8 - _photos.length)));
  }

  Future<void> _submit(ListingKind kind) async {
    if (!_form.currentState!.validate()) return;
    if (kind.hasHouse && _photos.isEmpty) {
      setState(() => _error = 'Ajoutez au moins une photo de la maison.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.of(context).publish(
        ListingDraft(
          kind: kind,
          title: _title.text.trim(),
          city: _city.text.trim(),
          neighborhood: _hood.text.trim(),
          description: _desc.text.trim(),
          conditions: _cond.text.trim(),
          rent: _n(_rent),
          caution: kind.hasHouse ? _n(_caution) : 0,
          serviceFee: kind.hasHouse ? _n(_fee) : 0,
          spots: _n(_spots).clamp(1, 99),
          houseState: kind.hasHouse ? _state : null,
          photos: kind.hasHouse ? _photos : const [],
        ),
      );
      if (!mounted) return;
      toast(context, 'Annonce publiée !');
      _form.currentState!.reset();
      for (final c in [
        _title,
        _city,
        _hood,
        _desc,
        _cond,
        _rent,
        _caution,
        _fee,
      ]) {
        c.clear();
      }
      setState(() {
        _photos.clear();
        _kind = null;
      });
      widget.onDone();
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Publication impossible. Réessayez.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Obligatoire' : null;

  Widget _money(
    TextEditingController c,
    String label, {
    bool required = false,
  }) => TextFormField(
    controller: c,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label, suffixText: 'FCFA'),
    validator: required ? (v) => _n(c) <= 0 ? 'Obligatoire' : null : null,
  );

  @override
  Widget build(BuildContext context) {
    final me = AppScope.of(context).user!;
    final isAgency = me.role == UserRole.agency;
    final kind = isAgency ? ListingKind.agency : _kind;

    return Scaffold(
      appBar: AppBar(title: const Text('Publier une annonce')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: kind == null
              ? ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Que souhaitez-vous faire ?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Choice(
                      index: 0,
                      gradient: kBrandGradient,
                      icon: Icons.home_work_outlined,
                      title: "J'ai une maison",
                      sub: 'Je propose une colocation',
                      onTap: () => setState(() => _kind = ListingKind.offer),
                    ),
                    const SizedBox(height: 12),
                    _Choice(
                      index: 1,
                      gradient: kAccentGradient,
                      icon: Icons.person_search_outlined,
                      title: 'Je cherche une colocation',
                      sub: "Je n'ai pas encore de maison",
                      onTap: () => setState(() => _kind = ListingKind.request),
                    ),
                  ],
                )
              : Form(
                  key: _form,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (!isAgency)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => setState(() => _kind = null),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Changer'),
                          ),
                        ),
                      KindBadge(kind),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _title,
                        decoration: InputDecoration(
                          labelText: 'Titre',
                          hintText: kind == ListingKind.request
                              ? 'Étudiant en L3 cherche colocation'
                              : '2 chambres libres près de la fac',
                        ),
                        validator: _req,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _city,
                              decoration: const InputDecoration(
                                labelText: 'Ville',
                              ),
                              validator: _req,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _hood,
                              decoration: const InputDecoration(
                                labelText: 'Quartier',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (kind.hasHouse) ...[
                        _PhotoPicker(
                          photos: _photos,
                          onAdd: _pick,
                          onRemove: (i) => setState(() => _photos.removeAt(i)),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _money(
                        _rent,
                        kind == ListingKind.request
                            ? 'Budget maximum / mois'
                            : (isAgency
                                  ? 'Loyer mensuel'
                                  : 'Loyer mensuel par personne'),
                        required: true,
                      ),
                      if (kind.hasHouse) ...[
                        const SizedBox(height: 12),
                        _money(_caution, 'Caution'),
                        const SizedBox(height: 12),
                        _money(_fee, 'Frais de prestation / d\'agence'),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _spots,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: kind == ListingKind.request
                              ? 'Nombre de personnes'
                              : 'Places disponibles',
                        ),
                      ),
                      if (kind.hasHouse) ...[
                        const SizedBox(height: 16),
                        const Text(
                          "État de la maison",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final s in HouseState.values)
                              ChoiceChip(
                                label: Text(s.label),
                                selected: _state == s,
                                onSelected: (_) => setState(() => _state = s),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _desc,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _cond,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Conditions',
                          hintText: kind.hasHouse
                              ? 'Durée minimale, règles de la maison, charges…'
                              : 'Date d\'arrivée souhaitée, préférences…',
                          alignLabelWithHint: true,
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      GradientButton(
                        label: "Publier l'annonce",
                        icon: Icons.rocket_launch_outlined,
                        busy: _busy,
                        onPressed: () => _submit(kind),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
    required this.gradient,
    this.index = 0,
  });
  final IconData icon;
  final String title, sub;
  final VoidCallback onTap;
  final LinearGradient gradient;
  final int index;
  @override
  Widget build(BuildContext context) => FadeSlideIn(
    index: index,
    child: Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: .35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .22),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(color: Colors.white.withValues(alpha: .9)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    ),
  );
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });
  final List<Uint8List> photos;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Photos de la maison',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 92,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (var i = 0; i < photos.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        photos[i],
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: InkWell(
                        onTap: () => onRemove(i),
                        child: const CircleAvatar(
                          radius: 11,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (photos.length < 8)
              InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined),
                      SizedBox(height: 4),
                      Text('Ajouter', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
