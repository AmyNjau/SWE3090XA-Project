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

  /// Entries per account id. Keeping them separate rather than clearing on
  /// sign-out means switching back to an account restores its own history, and
  /// one user can never see another's checks.
  final Map<String, List<HistoryEntry>> _byUser = {};
  String _uid = _anonymous;

  static const String _anonymous = '__anonymous__';

  List<HistoryEntry> get _entries => _byUser.putIfAbsent(_uid, () => []);

  /// Point the store at an account. Called by AuthGate on every auth change.
  void setUser(String? uid) {
    final next = uid ?? _anonymous;
    if (next == _uid) return;
    _uid = next;
    notifyListeners();
  }

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
