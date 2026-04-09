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

  /// Add a log [message] with optional [level], [tag], and [timestamp].
  ///
  /// [level] is a free-form severity label (e.g. `"info"`, `"warning"`).
  /// [tag] is a free-form category or logger name (e.g. `"MyService"`).
  ///
  /// If the buffer is at capacity the oldest entry is evicted.
  void add(String message, {String? level, String? tag, DateTime? timestamp}) {
    if (_entries.length >= capacity) {
      _entries.removeFirst();
    }
    _entries.addLast(
      LogEntry(
        message: message,
        level: level,
        tag: tag,
        timestamp: timestamp ?? DateTime.now(),
      ),
    );
  }

  /// Returns an unmodifiable view of all entries oldest-first.
  List<LogEntry> get entries => List<LogEntry>.unmodifiable(_entries);

  /// Formats the entire buffer as a single string suitable for writing to a
  /// text file attachment.
  ///
  /// Each line has the format:
  /// `{timestamp}  [{level}] {tag}: {message}` when level/tag are present,
  /// or `{timestamp}  {message}` for entries without metadata.
  String export() {
    final buf = StringBuffer();
    for (final entry in _entries) {
      final prefix = StringBuffer();
      if (entry.level != null) {
        prefix.write('[${entry.level}]');
      }
      if (entry.tag != null) {
        if (prefix.isNotEmpty) prefix.write(' ');
        prefix.write('${entry.tag}:');
      }
      if (prefix.isNotEmpty) {
        buf.writeln(
          '${entry.timestamp.toIso8601String()}  $prefix ${entry.message}',
        );
      } else {
        buf.writeln('${entry.timestamp.toIso8601String()}  ${entry.message}');
      }
    }
    return buf.toString();
  }

  /// Removes all entries from the buffer.
  void clear() => _entries.clear();
}

/// A single timestamped log entry.
class LogEntry {
  final String message;
  final String? level;
  final String? tag;
  final DateTime timestamp;

  const LogEntry({
    required this.message,
    this.level,
    this.tag,
    required this.timestamp,
  });
}
