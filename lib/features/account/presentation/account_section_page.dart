import 'package:flutter/material.dart';

import '../../../core/state/app_scope.dart';

enum AccountSection { personal, addresses, help }

class AccountSectionPage extends StatelessWidget {
  const AccountSectionPage({super.key, required this.section});

  final AccountSection section;

  @override
  Widget build(BuildContext context) => switch (section) {
    AccountSection.personal => const _PersonalInformationPage(),
    AccountSection.addresses => const _AddressesPage(),
    AccountSection.help => const _HelpSecurityPage(),
  };
}

class _PersonalInformationPage extends StatefulWidget {
  const _PersonalInformationPage();

  @override
  State<_PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<_PersonalInformationPage> {
  late final TextEditingController _name;
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _name = TextEditingController(
        text: AppScope.of(context).currentUser!.name,
      );
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Informations personnelles')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nom complet'),
              validator: (value) => value == null || value.trim().length < 2
                  ? 'Indiquez votre nom.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: user.email,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Adresse e-mail',
                helperText: 'L’adresse e-mail ne peut pas être modifiée ici.',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _name.text.trim();
    if (name.length < 2) return;
    setState(() => _saving = true);
    try {
      await AppScope.of(context).updateUserName(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informations mises à jour.')),
        );
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La mise à jour a échoué.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _AddressesPage extends StatefulWidget {
  const _AddressesPage();

  @override
  State<_AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<_AddressesPage> {
  final List<String> _addresses = <String>[];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mes adresses')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _addAddress,
      icon: const Icon(Icons.add),
      label: const Text('Ajouter'),
    ),
    body: _addresses.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Aucune adresse enregistrée. Ajoutez une adresse pour remplir vos prochaines demandes plus rapidement.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _addresses.length,
            itemBuilder: (context, index) => Card(
              child: ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(_addresses[index]),
                trailing: IconButton(
                  tooltip: 'Supprimer',
                  onPressed: () => setState(() => _addresses.removeAt(index)),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ),
          ),
  );

  Future<void> _addAddress() async {
    final controller = TextEditingController();
    final address = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une adresse'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Adresse',
            hintText: 'Ex. 12 rue des Jasmins, Tunis',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (address == null || address.isEmpty || !mounted) return;
    setState(() => _addresses.add(address));
  }
}

class _HelpSecurityPage extends StatelessWidget {
  const _HelpSecurityPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Aide et sécurité')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        ExpansionTile(
          leading: Icon(Icons.help_outline),
          title: Text('Comment créer une demande ?'),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Recherchez un artisan vérifié, ouvrez sa fiche puis choisissez Créer une demande.',
              ),
            ),
          ],
        ),
        ExpansionTile(
          leading: Icon(Icons.security_outlined),
          title: Text('Mes données sont-elles protégées ?'),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Les accès sont contrôlés par votre rôle et les règles de sécurité Firebase.',
              ),
            ),
          ],
        ),
        ExpansionTile(
          leading: Icon(Icons.support_agent_outlined),
          title: Text('Besoin d’aide supplémentaire ?'),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Contactez l’équipe QuickFix Tunisia avec la référence de votre demande.',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
