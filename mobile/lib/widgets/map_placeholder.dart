import 'package:flutter/material.dart';
import '../models/provider.dart';
import '../theme/app_theme.dart';

/// A lightweight stand-in for a real map. It plots provider pins at positions
/// derived from their coordinates so the screen is fully functional without a
/// Google Maps API key.
///
/// To switch to a real map later: add the `google_maps_flutter` dependency,
/// supply an API key in the Android/iOS manifests, and replace this widget with
/// a `GoogleMap` that renders `providers` as markers. No other screen changes
/// are required.
class MapPlaceholder extends StatelessWidget {
  final List<Provider> providers;
  const MapPlaceholder({super.key, required this.providers});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 200,
        width: double.infinity,
        color: const Color(0xFFEAF1EA),
        child: Stack(
          children: [
            // Faint "street" lines for visual texture.
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 8, color: AppColors.blue),
                    const SizedBox(width: 6),
                    Text(
                      '${providers.length} providers nearby',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            // Distribute pins across the area.
            ...List.generate(providers.length, (i) {
              final cols = 3;
              final dx = 40.0 + (i % cols) * 90.0;
              final dy = 60.0 + (i ~/ cols) * 60.0;
              return Positioned(
                left: dx,
                top: dy,
                child: const Icon(Icons.location_on, color: AppColors.blue, size: 30),
              );
            }),
            const Positioned(
              right: 12,
              bottom: 12,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.my_location, color: AppColors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 6;
    canvas.drawLine(Offset(0, size.height * 0.4),
        Offset(size.width, size.height * 0.55), paint);
    canvas.drawLine(Offset(size.width * 0.5, 0),
        Offset(size.width * 0.6, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
