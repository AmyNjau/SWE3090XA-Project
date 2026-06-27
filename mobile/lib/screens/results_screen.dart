import 'package:flutter/material.dart';

import '../models/diagnosis_result.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/condition_card.dart';
import '../widgets/specialist_panel.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/step_indicator.dart';
import 'providers_screen.dart';

/// Screen 2: ranked probable conditions and the recommended specialist.
class ResultsScreen extends StatefulWidget {
  final ApiService api;
  final List<String> symptomIds;

  const ResultsScreen({
    super.key,
    required this.api,
    required this.symptomIds,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  DiagnosisResult? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _diagnose();
  }

  Future<void> _diagnose() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.api.getDiagnosis(widget.symptomIds);
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _findDoctors(String specialist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProvidersScreen(api: widget.api, specialist: specialist),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Possible Conditions')),
      body: Column(
        children: [
          const StepIndicator(activeStep: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 40, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _diagnose, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final result = _result!;
    if (result.results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No likely conditions matched your symptoms. '
            'If you feel unwell, please consult a healthcare professional.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final top = result.results.first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        const Text(
          'BASED ON YOUR SYMPTOMS',
          style: TextStyle(
            color: AppColors.blue,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Ranked by how closely they match what you reported.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        // Top condition, emphasised.
        ConditionCard(condition: top, emphasised: true),
        // Recommended specialist for the top condition.
        if (result.recommendedSpecialist != null)
          SpecialistPanel(
            specialist: result.recommendedSpecialist!,
            description: result.specialistDescription,
            onFindDoctors: () => _findDoctors(result.recommendedSpecialist!),
          ),
        // Remaining conditions.
        ...result.results
            .skip(1)
            .map((c) => ConditionCard(condition: c)),
        const SizedBox(height: 8),
        DisclaimerBanner(text: result.disclaimer),
      ],
    );
  }
}
