import 'package:flutter/foundation.dart';

/// One past symptom check (mirrors the "Query" entity in the data model:
/// symptoms in, a ranked result out, with a timestamp).
class HistoryEntry {
  final DateTime timestamp;
  final List<String> symptomIds;
  final String topConditionName;
  final double topConfidence;
  final String? specialist;
  final String severity;

  const HistoryEntry({
    required this.timestamp,
    required this.symptomIds,
    required this.topConditionName,
    required this.topConfidence,
    required this.specialist,
    required this.severity,
  });
}

/// App-wide store of past symptom checks. In-memory for now (resets when the
/// app is killed); structured so it can later be persisted to local storage or
/// synced to the backend's Query collection without changing callers.
class HistoryStore extends ChangeNotifier {
  HistoryStore._();
  static final HistoryStore instance = HistoryStore._();

  final List<HistoryEntry> _entries = [];

  List<HistoryEntry> get entries => List.unmodifiable(_entries);
  int get count => _entries.length;

  void add(HistoryEntry entry) {
    _entries.insert(0, entry); // newest first
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}
