import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/billing_document.dart';
import '../../../core/models/intervention_request.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/widgets/responsive_page_layout.dart';
import '../data/billing_pdf_builder.dart';

class BillingDocumentPage extends StatefulWidget {
  const BillingDocumentPage({super.key, required this.request});

  final InterventionRequest request;

  @override
  State<BillingDocumentPage> createState() => _BillingDocumentPageState();
}

class _BillingDocumentPageState extends State<BillingDocumentPage> {
  final _formKey = GlobalKey<FormState>();
  final _issuerName = TextEditingController();
  final _issuerAddress = TextEditingController();
  final _taxId = TextEditingController();
  final _vatRate = TextEditingController();
  BillingDocument? _document;
  bool _loading = true;
  bool _saving = false;
  bool _preview = false;
  bool _published = false;
  bool _vatApplies = false;
  bool _loadStarted = false;
  String? _error;

  bool get _isArtisan {
    final user = AppScope.maybeOf(context)?.currentUser;
    return user?.role == UserRole.artisan &&
        user?.id == widget.request.artisanId;
  }

  @override
  void initState() {
    super.initState();
    _issuerName.text = widget.request.artisanName;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted) return;
    _loadStarted = true;
    _load();
  }

  Future<void> _load() async {
    try {
      final controller = AppScope.of(context);
      final request = await controller.getRequest(widget.request.id);
      final document = request == null
          ? null
          : await controller.getBillingDocument(request);
      final clientAddress = request != null && document == null && _isArtisan
          ? await controller.getRequestFullAddress(request)
          : null;
      if (!mounted) return;
      setState(() {
        _request = request;
        _document = document;
        _published = document != null;
        _clientAddress = clientAddress;
        _preview = document != null;
        _loading = false;
        _error = request == null ? 'Demande introuvable.' : null;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Le document n’a pas pu être chargé.';
      });
    }
  }

  InterventionRequest? _request;
  String? _clientAddress;

  @override
  void dispose() {
    _issuerName.dispose();
    _issuerAddress.dispose();
    _taxId.dispose();
    _vatRate.dispose();
    super.dispose();
  }

  BillingDocument _draft(InterventionRequest request) => BillingDocument(
    requestId: request.id,
    artisanId: request.artisanId,
    clientId: request.clientId,
    issuerName: _issuerName.text.trim(),
    issuerAddress: _issuerAddress.text.trim(),
    taxId: _taxId.text.trim(),
    vatRate: _vatApplies ? int.parse(_vatRate.text.trim()) : 0,
    clientName: request.clientName,
    clientAddress: _clientAddress ?? request.address,
    service: request.service,
    workPerformed: request.interventionReport!.workPerformed,
    serviceDate: request.date,
    diagnosis: request.interventionReport!.diagnosis ?? '',
    materials: request.interventionReport!.materials ?? '',
    clientAdvice: request.interventionReport!.clientAdvice ?? '',
    totalMillimes: request.quoteAmount! * 1000,
  );

  void _showPreview() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _document = _draft(_request!);
      _preview = true;
    });
  }

  Future<void> _publish() async {
    final document = _document;
    if (document == null || _saving) return;
    setState(() => _saving = true);
    try {
      final controller = AppScope.of(context);
      await controller.createBillingDocument(document);
      final saved = await controller.getBillingDocument(_request!);
      if (!mounted) return;
      setState(() {
        _document = saved;
        _published = saved != null;
        _error = saved == null ? 'Le document n’a pas pu être relu.' : null;
      });
      if (saved != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Projet de facture disponible pour le client.'),
          ),
        );
      }
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enregistrement impossible. Réessayez.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    final document = _document;
    return Scaffold(
      appBar: AppBar(title: const Text('Projet de facture')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _loading = true;
                          _error = null;
                        });
                        _load();
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
            : request == null || request.status != RequestStatus.completed
            ? const Center(child: Text('Intervention non terminée.'))
            : _preview && document != null
            ? _buildPreview(document)
            : _isArtisan &&
                  request.quoteAmount != null &&
                  request.interventionReport != null
            ? _buildForm(request)
            : const Center(
                child: Text(
                  'Aucun document disponible pour cette intervention.',
                ),
              ),
      ),
    );
  }

  Widget _buildForm(InterventionRequest request) => ResponsivePageLayout(
    child: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Informations de l’émetteur',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Renseignez vos vraies coordonnées. Elles figureront sur le document partagé avec le client.',
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _issuerName,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Nom ou raison sociale',
            ),
            validator: (value) => (value?.trim().length ?? 0) < 2
                ? 'Indiquez le nom de l’émetteur.'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _issuerAddress,
            maxLength: 200,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Adresse professionnelle',
            ),
            validator: (value) => (value?.trim().length ?? 0) < 5
                ? 'Indiquez votre adresse professionnelle.'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _taxId,
            maxLength: 32,
            decoration: const InputDecoration(labelText: 'Matricule fiscal'),
            validator: (value) => (value?.trim().isEmpty ?? true)
                ? 'Indiquez votre matricule fiscal.'
                : null,
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            title: const Text('TVA applicable'),
            subtitle: const Text('Choisissez selon votre régime fiscal.'),
            value: _vatApplies,
            onChanged: (value) => setState(() => _vatApplies = value),
          ),
          if (_vatApplies) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _vatRate,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Taux de TVA (%)',
                helperText: 'Saisissez le taux applicable à cette prestation.',
              ),
              validator: (value) {
                final rate = int.tryParse(value?.trim() ?? '');
                return rate == null || rate < 1 || rate > 100
                    ? 'Saisissez un taux entre 1 et 100 %.'
                    : null;
              },
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Client : ${request.clientName}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            'Adresse de la prestation : ${_clientAddress ?? request.address}',
          ),
          const SizedBox(height: 12),
          Text('Prestation : ${request.service}'),
          Text('Devis accepté : ${request.quoteAmount} DT TTC'),
          const SizedBox(height: 24),
          const Text(
            'Le montant du document reste identique au devis accepté. Vérifiez les informations avant de le partager.',
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _showPreview,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Prévisualiser le PDF'),
          ),
        ],
      ),
    ),
  );

  Widget _buildPreview(BillingDocument document) {
    final saved = _published;
    return Column(
      children: [
        MaterialBanner(
          content: const Text(
            'Document local non validé par Tunisie TradeNet : il ne remplace pas une facture électronique officielle.',
          ),
          actions: [
            if (!saved)
              TextButton(
                onPressed: () => setState(() => _preview = false),
                child: const Text('Corriger'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
        Expanded(
          child: PdfPreview(
            build: (_) => const BillingPdfBuilder().build(document),
            pdfFileName: 'projet-facture-${document.requestId}.pdf',
            allowPrinting: saved,
            allowSharing: saved,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            initialPageFormat: PdfPageFormat.a4,
          ),
        ),
        if (!saved && _isArtisan)
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _saving ? null : _publish,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                _saving
                    ? 'Enregistrement…'
                    : 'Partager ce document avec le client',
              ),
            ),
          ),
      ],
    );
  }
}
