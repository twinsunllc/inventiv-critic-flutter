import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventiv_critic_flutter/log_buffer.dart';
import 'package:inventiv_critic_flutter/log_capture.dart';

void main() {
  group('LogCapture', () {
    late LogBuffer buffer;
    late LogCapture capture;

    setUp(() {
      buffer = LogBuffer();
      capture = LogCapture(buffer: buffer);
    });

    tearDown(() {
      capture.uninstall();
    });

    test('isInstalled is false before install()', () {
      expect(capture.isInstalled, isFalse);
    });

    test('install() sets isInstalled to true', () {
      capture.install();
      expect(capture.isInstalled, isTrue);
    });

    test('install() returns a Zone', () {
      final zone = capture.install();
      expect(zone, isNotNull);
    });

    test('print() inside the capture zone is buffered', () {
      final zone = capture.install();
      zone.run(() {
        print('test message');
      });
      expect(buffer.length, 1);
      expect(buffer.entries.first.message, 'test message');
    });

    test('multiple print() calls are captured in order', () {
      final zone = capture.install();
      zone.run(() {
        print('first');
        print('second');
        print('third');
      });
      expect(buffer.length, 3);
      expect(buffer.entries[0].message, 'first');
      expect(buffer.entries[1].message, 'second');
      expect(buffer.entries[2].message, 'third');
    });

    test('FlutterError.onError is captured', () {
      // Save and restore FlutterError.onError
      final originalHandler = FlutterError.onError;
      try {
        capture.install();

        FlutterError.onError?.call(
          FlutterErrorDetails(exception: Exception('test error')),
        );

        expect(buffer.length, greaterThanOrEqualTo(1));
        expect(buffer.entries.first.message, contains('[FlutterError]'));
        expect(buffer.entries.first.message, contains('test error'));
      } finally {
        capture.uninstall();
        FlutterError.onError = originalHandler;
      }
    });

    test('uninstall() restores previous FlutterError.onError', () {
      final originalHandler = FlutterError.onError;
      capture.install();
      capture.uninstall();
      expect(FlutterError.onError, originalHandler);
    });

    test('uninstall() sets isInstalled to false', () {
      capture.install();
      capture.uninstall();
      expect(capture.isInstalled, isFalse);
    });

    test('double install() is a no-op', () {
      capture.install();
      final zone2 = capture.install();
      // Second call returns current zone (no-op)
      expect(zone2, isNotNull);
    });

    test('double uninstall() is a no-op', () {
      capture.install();
      capture.uninstall();
      // Should not throw
      capture.uninstall();
      expect(capture.isInstalled, isFalse);
    });

    test('runZoned() captures print', () {
      capture.runZoned(() {
        print('via runZoned');
      });
      expect(buffer.length, 1);
      expect(buffer.entries.first.message, 'via runZoned');
    });

    test('uses default LogBuffer when none provided', () {
      final defaultCapture = LogCapture();
      defaultCapture.install();
      expect(defaultCapture.buffer, isNotNull);
      expect(defaultCapture.buffer.capacity, LogBuffer.defaultCapacity);
      defaultCapture.uninstall();
    });

    test('respects buffer capacity limit', () {
      final smallBuffer = LogBuffer(capacity: 3);
      final smallCapture = LogCapture(buffer: smallBuffer);
      final zone = smallCapture.install();
      zone.run(() {
        for (var i = 0; i < 10; i++) {
          print('msg-$i');
        }
      });
      expect(smallBuffer.length, 3);
      expect(smallBuffer.entries.last.message, 'msg-9');
      smallCapture.uninstall();
    });
  });
}
