import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/artisan_catalog.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/widgets/responsive_form_layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _error = null;
      _isSubmitting = true;
    });
    try {
      await AppScope.of(context).signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } on Exception {
      if (mounted) {
        setState(
          () => _error = 'Connexion impossible. Vérifiez vos identifiants.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.handyman_rounded,
                      size: 44,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'QuickFix Tunisia',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Un dépannage fiable, au bon moment.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Bon retour parmi nous',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connectez-vous pour retrouver vos demandes ou votre espace professionnel.',
              ),
              const SizedBox(height: 24),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.username],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Adresse e-mail',
                              hintText: 'vous@exemple.tn',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: _emailValidator,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Afficher le mot de passe'
                                    : 'Masquer le mot de passe',
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Indiquez votre mot de passe.'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _login,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Se connecter'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RegisterPage(),
                        ),
                      ),
                child: const Text('Créer un compte'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choisissez un compte client ou artisan. Les profils artisans sont validés par l’administration.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _startingPriceController = TextEditingController();
  UserRole _role = UserRole.client;
  ArtisanTrade? _trade;
  InterventionArea? _area;
  String? _error;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _startingPriceController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _error = null;
      _isSubmitting = true;
    });
    try {
      await AppScope.of(context).register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: _role,
        trade: _role == UserRole.artisan ? _trade : null,
        area: _role == UserRole.artisan ? _area : null,
        startingPrice: _role == UserRole.artisan
            ? int.tryParse(_startingPriceController.text)
            : null,
      );
      if (mounted) Navigator.of(context).pop();
    } on Exception {
      if (mounted) {
        setState(
          () =>
              _error = 'Création impossible. Essayez une autre adresse e-mail.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Créer un compte')),
    body: Form(
      key: _formKey,
      child: ResponsiveFormLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nom complet'),
              validator: (value) => value == null || value.trim().length < 2
                  ? 'Indiquez votre nom.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Adresse e-mail'),
              validator: _emailValidator,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                helperText: 'Au moins 6 caractères.',
              ),
              validator: (value) => value == null || value.length < 6
                  ? 'Le mot de passe doit contenir au moins 6 caractères.'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserRole>(
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: 'Type de compte',
                helperText:
                    'Les comptes artisans sont examinés avant validation.',
              ),
              items: const [
                DropdownMenuItem(value: UserRole.client, child: Text('Client')),
                DropdownMenuItem(
                  value: UserRole.artisan,
                  child: Text('Artisan'),
                ),
              ],
              onChanged: _isSubmitting
                  ? null
                  : (role) {
                      if (role != null) setState(() => _role = role);
                    },
            ),
            if (_role == UserRole.artisan) ...[
              const SizedBox(height: 24),
              Text(
                'Votre activité professionnelle',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ArtisanTrade>(
                initialValue: _trade,
                decoration: const InputDecoration(
                  labelText: 'Métier',
                  helperText: 'Choisissez votre activité principale.',
                ),
                items: ArtisanTrade.values
                    .map(
                      (trade) => DropdownMenuItem(
                        value: trade,
                        child: Text(trade.label),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (trade) => setState(() => _trade = trade),
                validator: (value) => _role == UserRole.artisan && value == null
                    ? 'Choisissez votre métier.'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<InterventionArea>(
                initialValue: _area,
                decoration: const InputDecoration(
                  labelText: 'Zone d’intervention',
                  helperText: 'Sélectionnez le gouvernorat principal.',
                ),
                items: InterventionArea.values
                    .map(
                      (area) => DropdownMenuItem(
                        value: area,
                        child: Text(area.label),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (area) => setState(() => _area = area),
                validator: (value) => _role == UserRole.artisan && value == null
                    ? 'Choisissez votre zone d’intervention.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _startingPriceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Tarif de départ (DT)',
                  helperText:
                      'Vous pourrez le faire valider par l’administration.',
                ),
                validator: (value) {
                  if (_role != UserRole.artisan) return null;
                  final price = int.tryParse(value ?? '');
                  return price == null || price < 0
                      ? 'Indiquez un tarif de départ valide.'
                      : null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Votre profil sera en attente de validation. Vous pourrez déjà accéder à votre espace professionnel.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _isSubmitting ? null : _register,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _role == UserRole.artisan
                          ? 'Créer mon compte artisan'
                          : 'Créer mon compte client',
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

String? _emailValidator(String? value) => value == null || !value.contains('@')
    ? 'Indiquez une adresse e-mail valide.'
    : null;
