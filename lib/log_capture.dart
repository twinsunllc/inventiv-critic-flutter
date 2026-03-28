import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:inventiv_critic_flutter/log_buffer.dart';

/// Captures Dart [print] output and Flutter framework errors into a
/// [LogBuffer].
///
/// Start capture by calling [install]. The captured zone is returned so the
/// caller can run their app inside it (required for [print] interception).
///
/// Flutter errors reported through [FlutterError.onError] are captured
/// regardless of zone, because [FlutterError.onError] is a global callback.
class LogCapture {
  LogCapture({LogBuffer? buffer}) : buffer = buffer ?? LogBuffer();

  final LogBuffer buffer;
  FlutterExceptionHandler? _previousErrorHandler;
  bool _installed = false;

  /// Whether [install] has been called.
  bool get isInstalled => _installed;

  /// Installs the capture hooks and returns a [Zone] whose [print] calls are
  /// intercepted. The caller should run their application inside this zone:
  ///
  /// ```dart
  /// final capture = LogCapture();
  /// final zone = capture.install();
  /// zone.run(() => runApp(MyApp()));
  /// ```
  Zone install() {
    if (_installed) return Zone.current;
    _installed = true;

    // Capture FlutterError.onError
    _previousErrorHandler = FlutterError.onError;
    FlutterError.onError = _handleFlutterError;

    // Create a zone that intercepts print()
    return Zone.current.fork(
      specification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
          buffer.add(line);
          // Still forward to the parent so output appears in the console.
          parent.print(zone, line);
        },
      ),
    );
  }

  /// Runs [body] inside the capture zone. Convenience wrapper around
  /// [install] + [Zone.run].
  T runZoned<T>(T Function() body) {
    final zone = install();
    return zone.run(body);
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    buffer.add('[FlutterError] ${details.exceptionAsString()}');
    if (details.stack != null) {
      buffer.add(details.stack.toString());
    }
    // Forward to the previous handler (or the default one).
    final previous = _previousErrorHandler ?? FlutterError.presentError;
    previous(details);
  }

  /// Removes the capture hooks. After calling this, new [print] calls and
  /// Flutter errors are no longer captured.
  void uninstall() {
    if (!_installed) return;
    _installed = false;
    FlutterError.onError = _previousErrorHandler;
    _previousErrorHandler = null;
  }
}
