import 'package:flutter/material.dart';

import '../config.dart';
import '../data/repository.dart';
import '../models.dart';
import '../state/app_state.dart';
import 'logo.dart';
import 'theme.dart';
import 'widgets.dart';

/// Connexion / inscription. Renvoie `true` à la fermeture si l'utilisateur est connecté.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  bool _signup = false;
  UserRole _role = UserRole.student;
  final _name = TextEditingController(),
      _agency = TextEditingController(),
      _phone = TextEditingController();
  final _email = TextEditingController(), _pass = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _agency, _phone, _email, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final s = AppScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_signup) {
        await s.signUp(
          email: _email.text.trim(),
          password: _pass.text,
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          role: _role,
          agencyName: _role == UserRole.agency ? _agency.text.trim() : null,
        );
      } else {
        await s.signIn(_email.text.trim(), _pass.text);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Une erreur est survenue. Réessayez.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Obligatoire' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: kInk),
                  ),
                ),
                const ColocLogo(size: 76),
                const SizedBox(height: 10),
                Text(
                  _signup ? 'Rejoins Colloc' : 'Bon retour !',
                  style: const TextStyle(
                    color: kInk,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _signup
                      ? 'Crée ton compte en 30 secondes'
                      : 'Connecte-toi pour publier et contacter',
                  style: TextStyle(color: kInk.withValues(alpha: .7)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _form,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (_signup) ...[
                        SegmentedButton<UserRole>(
                          segments: const [
                            ButtonSegment(
                              value: UserRole.student,
                              label: Text('Étudiant'),
                              icon: Icon(Icons.school_outlined),
                            ),
                            ButtonSegment(
                              value: UserRole.agency,
                              label: Text('Agence'),
                              icon: Icon(Icons.apartment_outlined),
                            ),
                          ],
                          selected: {_role},
                          onSelectionChanged: (v) =>
                              setState(() => _role = v.first),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Nom complet',
                          ),
                          validator: _req,
                        ),
                        const SizedBox(height: 12),
                        if (_role == UserRole.agency) ...[
                          TextFormField(
                            controller: _agency,
                            decoration: const InputDecoration(
                              labelText: "Nom de l'agence",
                            ),
                            validator: _req,
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Téléphone / WhatsApp',
                            helperText: 'Visible seulement après paiement de la mise en contact',
                          ),
                          validator: (v) => (v == null || v.trim().length < 8)
                              ? 'Numéro invalide'
                              : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'E-mail'),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'E-mail invalide'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pass,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Mot de passe',
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? '6 caractères minimum'
                            : null,
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
                        label: _signup ? "S'inscrire" : 'Se connecter',
                        busy: _busy,
                        onPressed: _submit,
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _signup = !_signup;
                          _error = null;
                        }),
                        child: Text(
                          _signup
                              ? 'J\'ai déjà un compte'
                              : 'Pas de compte ? Créer un compte',
                        ),
                      ),
                      if (AppConfig.isDemo && !_signup) ...[
                        const Divider(height: 32),
                        const Text(
                          'Mode démo — connexion rapide :',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: [
                            ActionChip(
                              label: const Text('Étudiant'),
                              onPressed: () {
                                _email.text = 'etudiant@demo.com';
                                _pass.text = 'demo1234';
                                _submit();
                              },
                            ),
                            ActionChip(
                              label: const Text('Admin'),
                              onPressed: () {
                                _email.text = 'admin@demo.com';
                                _pass.text = 'demo1234';
                                _submit();
                              },
                            ),
                            ActionChip(
                              label: const Text('Agence'),
                              onPressed: () {
                                _email.text = 'agence@demo.com';
                                _pass.text = 'demo1234';
                                _submit();
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
