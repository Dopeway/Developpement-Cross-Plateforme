import 'package:flutter/material.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/intervention_report.dart';
import '../../../core/models/intervention_request.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/widgets/request_status_widgets.dart';
import '../../../core/widgets/responsive_page_layout.dart';

class InterventionReportPage extends StatefulWidget {
  const InterventionReportPage({super.key, required this.request});

  final InterventionRequest request;

  @override
  State<InterventionReportPage> createState() => _InterventionReportPageState();
}

class _InterventionReportPageState extends State<InterventionReportPage> {
  final _formKey = GlobalKey<FormState>();
  late InterventionRequest _request;
  late final TextEditingController _workPerformedController;
  late final TextEditingController _diagnosisController;
  late final TextEditingController _materialsController;
  late final TextEditingController _adviceController;
  bool _saving = false;
  bool _loadingReport = true;
  bool _reportLoadFailed = false;
  bool _initialLoadStarted = false;

  bool get _isEditable {
    final user = AppScope.maybeOf(context)?.currentUser;
    return user?.role == UserRole.artisan &&
        user?.id == _request.artisanId &&
        _request.status == RequestStatus.inProgress;
  }

  @override
  void initState() {
    super.initState();
    _request = widget.request;
    final report = _request.interventionReport;
    _workPerformedController = TextEditingController(
      text: report?.workPerformed ?? '',
    );
    _diagnosisController = TextEditingController(text: report?.diagnosis ?? '');
    _materialsController = TextEditingController(text: report?.materials ?? '');
    _adviceController = TextEditingController(text: report?.clientAdvice ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialLoadStarted) return;
    _initialLoadStarted = true;
    _loadCurrentRequest();
  }

  Future<void> _loadCurrentRequest() async {
    try {
      final currentRequest = await AppScope.of(context).getRequest(_request.id);
      if (!mounted) return;
      if (currentRequest == null) {
        setState(() {
          _loadingReport = false;
          _reportLoadFailed = true;
        });
        return;
      }
      final report = currentRequest.interventionReport;
      setState(() {
        _request = currentRequest;
        _workPerformedController.text = report?.workPerformed ?? '';
        _diagnosisController.text = report?.diagnosis ?? '';
        _materialsController.text = report?.materials ?? '';
        _adviceController.text = report?.clientAdvice ?? '';
        _loadingReport = false;
        _reportLoadFailed = false;
      });
    } on Exception {
      if (mounted) {
        setState(() {
          _loadingReport = false;
          _reportLoadFailed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _workPerformedController.dispose();
    _diagnosisController.dispose();
    _materialsController.dispose();
    _adviceController.dispose();
    super.dispose();
  }

  InterventionReport _report() => InterventionReport(
    workPerformed: _workPerformedController.text,
    diagnosis: _diagnosisController.text,
    materials: _materialsController.text,
    clientAdvice: _adviceController.text,
  );

  @override
  Widget build(BuildContext context) {
    final report = _request.interventionReport;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditable ? 'Rapport d’intervention' : 'Intervention terminée',
        ),
      ),
      body: SafeArea(
        child: ResponsivePageLayout(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              _ReportHeader(request: _request, editable: _isEditable),
              const SizedBox(height: 24),
              if (_loadingReport)
                const _ReportLoadingView()
              else if (_reportLoadFailed)
                _ReportLoadError(
                  onRetry: () {
                    setState(() {
                      _loadingReport = true;
                      _reportLoadFailed = false;
                    });
                    _loadCurrentRequest();
                  },
                )
              else if (_isEditable)
                _buildEditor()
              else
                _ReportSummary(report: report),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditor() => Form(
    key: _formKey,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Consignez ce qui a été fait avant de clôturer. Le client recevra ce récapitulatif.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        _FormSection(
          title: 'Travaux réalisés',
          child: TextFormField(
            controller: _workPerformedController,
            minLines: 4,
            maxLines: 8,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Décrivez l’intervention',
              hintText: 'Ex. Remplacement du joint et test de l’étanchéité.',
              helperText: '10 caractères minimum pour enregistrer ou terminer.',
            ),
            validator: (value) {
              if (value == null || value.trim().length < 10) {
                return 'Décrivez les travaux réalisés en au moins 10 caractères.';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 20),
        _FormSection(
          title: 'Informations complémentaires',
          child: Column(
            children: [
              TextFormField(
                controller: _diagnosisController,
                minLines: 2,
                maxLines: 5,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Diagnostic',
                  hintText: 'Cause constatée, si utile',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _materialsController,
                minLines: 2,
                maxLines: 5,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Matériaux ou pièces utilisés',
                  hintText: 'Facultatif',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _adviceController,
                minLines: 2,
                maxLines: 5,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Conseils au client',
                  hintText: 'Entretien, précaution ou prochaine étape',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: _saving ? null : _saveDraft,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Enregistrer le brouillon'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _saving ? null : _complete,
          icon: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.task_alt_outlined),
          label: Text(_saving ? 'Enregistrement…' : 'Terminer l’intervention'),
        ),
      ],
    ),
  );

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AppScope.of(context)
          .saveInterventionReport(request: _request, report: _report());
      if (mounted) _showMessage('Brouillon enregistré.');
    } on ArgumentError catch (error) {
      if (mounted) {
        _showMessage(error.message?.toString() ?? 'Rapport invalide.');
      }
    } on Exception {
      if (mounted) _showMessage('Le brouillon n’a pas pu être enregistré.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _complete() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AppScope.of(context)
          .completeIntervention(request: _request, report: _report());
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Intervention terminée et rapport envoyé.'),
        ),
      );
    } on ArgumentError catch (error) {
      if (mounted) {
        _showMessage(error.message?.toString() ?? 'Rapport invalide.');
      }
    } on Exception {
      if (mounted) _showMessage('La clôture n’a pas pu être enregistrée.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}

class _ReportLoadingView extends StatelessWidget {
  const _ReportLoadingView();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 48),
    child: Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Chargement du brouillon…'),
      ],
    ),
  );
}

class _ReportLoadError extends StatelessWidget {
  const _ReportLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Le brouillon n’a pas pu être chargé. Vérifiez votre connexion puis réessayez.',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Réessayer'),
      ),
    ],
  );
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.request, required this.editable});

  final InterventionRequest request;
  final bool editable;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.handyman_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                request.service,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            RequestStatusChip(status: request.status),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          editable
              ? 'Intervention en cours chez ${request.clientName}'
              : 'Intervention réalisée par ${request.artisanName}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (request.quoteAmount != null) ...[
          const SizedBox(height: 12),
          Text(
            'Devis accepté : ${request.quoteAmount} DT TTC',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ],
    ),
  );
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 10),
      child,
    ],
  );
}

class _ReportSummary extends StatelessWidget {
  const _ReportSummary({required this.report});

  final InterventionReport? report;

  @override
  Widget build(BuildContext context) {
    if (report == null) {
      return const _EmptyReport();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryBlock(label: 'Travaux réalisés', value: report!.workPerformed),
        if (_hasContent(report!.diagnosis))
          _SummaryBlock(label: 'Diagnostic', value: report!.diagnosis!),
        if (_hasContent(report!.materials))
          _SummaryBlock(
            label: 'Matériaux ou pièces utilisés',
            value: report!.materials!,
          ),
        if (_hasContent(report!.clientAdvice))
          _SummaryBlock(label: 'Conseils', value: report!.clientAdvice!),
      ],
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}

class _EmptyReport extends StatelessWidget {
  const _EmptyReport();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Text(
      'Le rapport détaillé n’est pas disponible pour cette intervention.',
    ),
  );
}

bool _hasContent(String? value) => value != null && value.trim().isNotEmpty;
