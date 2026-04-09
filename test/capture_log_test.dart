import 'package:flutter_test/flutter_test.dart';
import 'package:inventiv_critic_flutter/critic.dart';
import 'package:inventiv_critic_flutter/log_buffer.dart';

void main() {
  group('Critic.captureLog', () {
    late LogBuffer buffer;

    setUp(() {
      // Access the shared LogCapture buffer directly to inspect captured entries.
      buffer = Critic.instance.logCapture.buffer;
      buffer.clear();
    });

    tearDown(() {
      buffer.clear();
    });

    test('captureLog() adds entry to the log buffer', () {
      Critic.instance.captureLog('hello');
      expect(buffer.length, 1);
      expect(buffer.entries.first.message, 'hello');
    });

    test('captureLog() stores level on the entry', () {
      Critic.instance.captureLog('msg', level: 'info');
      expect(buffer.entries.first.level, 'info');
    });

    test('captureLog() stores tag on the entry', () {
      Critic.instance.captureLog('msg', tag: 'MyLogger');
      expect(buffer.entries.first.tag, 'MyLogger');
    });

    test('captureLog() stores all optional metadata', () {
      final ts = DateTime(2026, 4, 9, 12, 0, 0);
      Critic.instance.captureLog(
        'structured log',
        level: 'warning',
        tag: 'AuthService',
        timestamp: ts,
      );
      final entry = buffer.entries.first;
      expect(entry.message, 'structured log');
      expect(entry.level, 'warning');
      expect(entry.tag, 'AuthService');
      expect(entry.timestamp, ts);
    });

    test('captureLog() defaults timestamp to now when not provided', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      Critic.instance.captureLog('time test');
      final after = DateTime.now().add(const Duration(seconds: 1));
      final ts = buffer.entries.first.timestamp;
      expect(ts.isAfter(before), isTrue);
      expect(ts.isBefore(after), isTrue);
    });

    test('captureLog() level and tag are null when omitted', () {
      Critic.instance.captureLog('plain');
      final entry = buffer.entries.first;
      expect(entry.level, isNull);
      expect(entry.tag, isNull);
    });

    test('captureLog() entries appear in export() output', () {
      final ts = DateTime(2026, 4, 9, 10, 0, 0);
      Critic.instance.captureLog(
        'exported log',
        level: 'info',
        tag: 'App',
        timestamp: ts,
      );
      final output = buffer.export();
      expect(output, contains('exported log'));
      expect(output, contains('[info]'));
      expect(output, contains('App:'));
    });

    test('captureLog() multiple entries are captured in order', () {
      Critic.instance.captureLog('first', level: 'debug');
      Critic.instance.captureLog('second', level: 'info');
      Critic.instance.captureLog('third', level: 'warning');
      expect(buffer.length, 3);
      expect(buffer.entries[0].message, 'first');
      expect(buffer.entries[1].message, 'second');
      expect(buffer.entries[2].message, 'third');
    });

    test('Critic.instance returns the same singleton as Critic()', () {
      expect(identical(Critic.instance, Critic()), isTrue);
    });

    test('captureLog() entries share the buffer with print() capture', () {
      // Verify captureLog writes to the same buffer accessed via logCapture.
      final directBuffer = Critic.instance.logCapture.buffer;
      Critic.instance.captureLog('from logger');
      expect(
        directBuffer.entries.any((e) => e.message == 'from logger'),
        isTrue,
      );
    });
  });
}
