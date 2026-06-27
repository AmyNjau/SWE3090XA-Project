import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/provider.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/provider_card.dart';
import '../widgets/map_placeholder.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/step_indicator.dart';

/// Screen 3: nearby providers for the recommended specialist, shown as a map
/// plus a distance-sorted list.
class ProvidersScreen extends StatefulWidget {
  final ApiService api;
  final String specialist;
  final LocationService? locationService;

  const ProvidersScreen({
    super.key,
    required this.api,
    required this.specialist,
    this.locationService,
  });

  @override
  State<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends State<ProvidersScreen> {
  late final LocationService _location;
  List<Provider> _providers = [];
  bool _loading = true;
  String? _error;
  bool _usedFallbackLocation = false;

  @override
  void initState() {
    super.initState();
    _location = widget.locationService ?? LocationService();
    _load();
  }

  /// Opens the device's map app with directions to the provider. Falls back to
  /// a message if no map app can handle the request, so it never crashes.
  Future<void> _openDirections(Provider p) async {
    if (p.latitude == null || p.longitude == null) return;
    final query = '${p.latitude},${p.longitude}';
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    bool opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open a map for ${p.name}.')),
      );
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loc = await _location.getCurrentLocation();
      final providers = await widget.api.getNearbyProviders(
        specialist: widget.specialist,
        latitude: loc.latitude,
        longitude: loc.longitude,
      );
      setState(() {
        _providers = providers;
        _usedFallbackLocation = loc.isFallback;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Providers')),
      body: Column(
        children: [
          const StepIndicator(activeStep: 2),
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
              OutlinedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: MapPlaceholder(providers: _providers),
        ),
        if (_usedFallbackLocation)
          Container(
            width: double.infinity,
            color: AppColors.lightBlue,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: const Text(
              'Using a default location — enable location access for results near you.',
              style: TextStyle(fontSize: 12, color: AppColors.navy),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.specialist,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.navy,
                ),
              ),
              const Text(
                'Sort: Distance',
                style: TextStyle(color: AppColors.blue, fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: _providers.isEmpty
              ? const Center(
                  child: Text(
                    'No providers found nearby for this specialist.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  children: _providers
                      .map((p) => ProviderCard(
                            provider: p,
                            onDirections: () => _openDirections(p),
                          ))
                      .toList(),
                ),
        ),
        const DisclaimerBanner(),
      ],
    );
  }
}
