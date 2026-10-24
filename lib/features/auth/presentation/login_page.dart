import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/state/demo_scope.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    final success = DemoScope.of(
      context,
    ).login(email: _emailController.text, password: _passwordController.text);
    if (!success) {
      setState(() => _error = 'Identifiants incorrects. Réessayez.');
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
  }

  void _useDemoAccount(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 36),
              Icon(
                Icons.handyman_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'QuickFix Tunisia',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Connectez-vous pour utiliser la démonstration locale.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Adresse e-mail',
                        hintText: 'vous@quickfix.tn',
                      ),
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Indiquez une adresse e-mail valide.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe',
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Indiquez votre mot de passe.'
                          : null,
                    ),
                  ],
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
                onPressed: _login,
                child: const Text('Se connecter'),
              ),
              const SizedBox(height: 28),
              Text(
                'Comptes de démonstration',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _DemoAccountButton(
                label: 'Client — Amira Khalfallah',
                onPressed: () =>
                    _useDemoAccount('client@quickfix.tn', 'client123'),
              ),
              _DemoAccountButton(
                label: 'Artisan — Sami Ben Salem',
                onPressed: () =>
                    _useDemoAccount('artisan@quickfix.tn', 'artisan123'),
              ),
              _DemoAccountButton(
                label: 'Administration',
                onPressed: () =>
                    _useDemoAccount('admin@quickfix.tn', 'admin123'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ces comptes sont fictifs : les changements sont conservés seulement pendant cette session.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DemoAccountButton extends StatelessWidget {
  const _DemoAccountButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.login),
      label: Text(label),
    ),
  );
}
