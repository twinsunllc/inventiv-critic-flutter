import 'dart:collection';

/// A fixed-capacity ring buffer that stores the most recent log entries.
///
/// When the buffer reaches [capacity], the oldest entry is discarded to make
/// room for each new entry. This ensures bounded memory usage.
class LogBuffer {
  /// Default maximum number of entries retained.
  static const int defaultCapacity = 500;

  final int capacity;
  final Queue<LogEntry> _entries = Queue<LogEntry>();

  LogBuffer({this.capacity = defaultCapacity});

  /// Number of entries currently in the buffer.
  int get length => _entries.length;

  /// Whether the buffer contains no entries.
  bool get isEmpty => _entries.isEmpty;

  /// Add a log [message] with an optional [timestamp].
  ///
  /// If the buffer is at capacity the oldest entry is evicted.
  void add(String message, {DateTime? timestamp}) {
    if (_entries.length >= capacity) {
      _entries.removeFirst();
    }
    _entries.addLast(
      LogEntry(message: message, timestamp: timestamp ?? DateTime.now()),
    );
  }

  /// Returns an unmodifiable view of all entries oldest-first.
  List<LogEntry> get entries => List<LogEntry>.unmodifiable(_entries);

  /// Formats the entire buffer as a single string suitable for writing to a
  /// text file attachment.
  String export() {
    final buf = StringBuffer();
    for (final entry in _entries) {
      buf.writeln('${entry.timestamp.toIso8601String()}  ${entry.message}');
    }
    return buf.toString();
  }

  /// Removes all entries from the buffer.
  void clear() => _entries.clear();
}

/// A single timestamped log entry.
class LogEntry {
  final String message;
  final DateTime timestamp;

  const LogEntry({required this.message, required this.timestamp});
}
