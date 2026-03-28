import 'package:flutter_test/flutter_test.dart';
import 'package:inventiv_critic_flutter/log_buffer.dart';

void main() {
  group('LogBuffer', () {
    test('starts empty', () {
      final buffer = LogBuffer();
      expect(buffer.isEmpty, isTrue);
      expect(buffer.length, 0);
      expect(buffer.entries, isEmpty);
    });

    test('add() stores entries', () {
      final buffer = LogBuffer();
      buffer.add('hello');
      buffer.add('world');
      expect(buffer.length, 2);
      expect(buffer.entries[0].message, 'hello');
      expect(buffer.entries[1].message, 'world');
    });

    test('uses provided timestamp', () {
      final buffer = LogBuffer();
      final ts = DateTime(2026, 1, 15, 12, 0, 0);
      buffer.add('msg', timestamp: ts);
      expect(buffer.entries.first.timestamp, ts);
    });

    test('evicts oldest entry when capacity reached', () {
      final buffer = LogBuffer(capacity: 3);
      buffer.add('a');
      buffer.add('b');
      buffer.add('c');
      buffer.add('d');
      expect(buffer.length, 3);
      expect(buffer.entries[0].message, 'b');
      expect(buffer.entries[1].message, 'c');
      expect(buffer.entries[2].message, 'd');
    });

    test('default capacity is 500', () {
      final buffer = LogBuffer();
      expect(buffer.capacity, 500);
    });

    test('ring buffer handles filling exactly to capacity', () {
      final buffer = LogBuffer(capacity: 3);
      buffer.add('a');
      buffer.add('b');
      buffer.add('c');
      expect(buffer.length, 3);
      expect(buffer.entries.map((e) => e.message).toList(), ['a', 'b', 'c']);
    });

    test('ring buffer eviction at large scale', () {
      final buffer = LogBuffer(capacity: 500);
      for (var i = 0; i < 600; i++) {
        buffer.add('msg-$i');
      }
      expect(buffer.length, 500);
      expect(buffer.entries.first.message, 'msg-100');
      expect(buffer.entries.last.message, 'msg-599');
    });

    test('clear() empties the buffer', () {
      final buffer = LogBuffer();
      buffer.add('a');
      buffer.add('b');
      buffer.clear();
      expect(buffer.isEmpty, isTrue);
      expect(buffer.length, 0);
    });

    test('export() formats entries with timestamp and message', () {
      final buffer = LogBuffer();
      final ts = DateTime(2026, 3, 28, 10, 30, 0);
      buffer.add('first line', timestamp: ts);
      buffer.add('second line', timestamp: ts);

      final output = buffer.export();
      expect(output, contains('2026-03-28'));
      expect(output, contains('first line'));
      expect(output, contains('second line'));
      // Each line ends with newline
      expect(output.trim().split('\n').length, 2);
    });

    test('export() returns empty string for empty buffer', () {
      final buffer = LogBuffer();
      expect(buffer.export(), '');
    });

    test('entries returns unmodifiable list', () {
      final buffer = LogBuffer();
      buffer.add('test');
      final entries = buffer.entries;
      expect(
        () => entries.add(LogEntry(message: 'x', timestamp: DateTime.now())),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
