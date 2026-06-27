import 'package:flutter/material.dart';

import '../models/symptom.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/symptom_chip.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/step_indicator.dart';
import '../widgets/app_drawer.dart';
import 'results_screen.dart';

/// Screen 1: the user searches and selects symptoms, then analyses them.
class SymptomInputScreen extends StatefulWidget {
  final ApiService api;
  const SymptomInputScreen({super.key, required this.api});

  @override
  State<SymptomInputScreen> createState() => _SymptomInputScreenState();
}

class _SymptomInputScreenState extends State<SymptomInputScreen> {
  final _searchController = TextEditingController();
  final Set<String> _selected = {};

  List<Symptom> _all = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadSymptoms();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSymptoms() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final symptoms = await widget.api.fetchSymptoms();
      setState(() {
        _all = symptoms;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _analyse() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one symptom.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          api: widget.api,
          symptomIds: _selected.toList(),
        ),
      ),
    );
  }

  /// Chips to show: when searching, matches across the whole catalogue;
  /// otherwise the curated "common" quick-picks plus anything already selected.
  List<Symptom> get _visibleChips {
    if (_query.isNotEmpty) {
      return _all
          .where((s) => s.name.toLowerCase().contains(_query))
          .toList();
    }
    return _all.where((s) => s.common || _selected.contains(s.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Check Your Symptoms'),
      ),
      body: Column(
        children: [
          const StepIndicator(activeStep: 0),
          Expanded(child: _buildBody()),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _selected.isEmpty ? null : _analyse,
                    child: const Text('Analyse Symptoms'),
                  ),
                  const DisclaimerBanner(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _loadSymptoms);
    }
    final chips = _visibleChips;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Add the symptoms you're experiencing and we'll suggest what to do next.",
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('SYMPTOM'),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Type a symptom…',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD8DDE5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD8DDE5)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionLabel(_query.isEmpty ? 'COMMON SYMPTOMS' : 'MATCHES'),
              Text(
                '${_selected.length} selected',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (chips.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No matching symptoms.',
                  style: TextStyle(color: AppColors.textMuted)),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: chips
                  .map((s) => SymptomChip(
                        label: s.name,
                        selected: _selected.contains(s.id),
                        onTap: () => _toggle(s.id),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.blue,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
