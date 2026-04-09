# inventiv_critic_flutter

A Flutter client SDK for submitting bug reports to [Inventiv Critic](https://critictracking.com/getting-started/). Supports the Critic v3 API. This SDK is designed for embedding in end-user apps and supports only report submission — administrative endpoints (listing reports, fetching individual reports, listing devices) are not included and should be accessed through the Critic web portal or server-side API instead.

## Requirements

- Dart SDK >=3.7.0
- Flutter 3.x
- A Critic account and API token — visit [the Critic website](https://critictracking.com/getting-started/) for setup instructions.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  inventiv_critic_flutter: ^1.0.0
```

Or use the git repository directly:

```yaml
dependencies:
  inventiv_critic_flutter:
    git:
      url: https://github.com/twinsunllc/inventiv-critic-flutter.git
```

## Usage

### 1. Import the package

```dart
import 'package:inventiv_critic_flutter/inventiv_critic_flutter.dart';
```

### 2. Initialize Critic

Call `initialize` with your API token. This performs a ping to register the app install with Critic.

```dart
await Critic().initialize('your-api-token');
```

To use a custom API endpoint:

```dart
await Critic().initialize('your-api-token', baseUrl: 'https://your-server.com/api/v3');
```

### 3. Submit a bug report

```dart
final report = BugReport.create(
  description: 'App crashes when tapping the save button',
  stepsToReproduce: '1. Open settings\n2. Change name\n3. Tap save',
  userIdentifier: 'user@example.com',
);

final submittedReport = await Critic().submitReport(report);
print('Report submitted with ID: ${submittedReport.id}');
```

### 4. Attach files (optional)

```dart
final report = BugReport.create(
  description: 'Layout broken on tablet',
  stepsToReproduce: '1. Open on iPad\n2. Rotate to landscape',
);

report.attachments = [
  Attachment(name: 'screenshot.png', path: '/path/to/screenshot.png'),
];

await Critic().submitReport(report);
```

## Capturing logs from third-party loggers

The SDK exposes `Critic.instance.captureLog()` so you can forward messages from
any logging package directly into the `console-logs.txt` attachment. The SDK
itself has **no dependency** on any logging library — you wire it in your own
app code.

```dart
void captureLog(
  String message, {
  String? level,     // e.g. "info", "warning", "severe"
  String? tag,       // e.g. logger name or subsystem
  DateTime? timestamp,
})
```

### package:logging

```dart
Logger.root.level = Level.ALL;
Logger.root.onRecord.listen((record) {
  Critic.instance.captureLog(
    record.message,
    level: record.level.name,
    tag: record.loggerName,
    timestamp: record.time,
  );
});
```

### package:logger

Write a small `LogOutput` subclass that forwards to `captureLog`:

```dart
class CriticLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      Critic.instance.captureLog(line, level: event.level.name);
    }
  }
}

// Then pass it to your Logger:
final logger = Logger(output: CriticLogOutput());
```

### dart:developer log()

Calls to `dart:developer`'s `log()` bypass the Dart Zone mechanism and go
directly to the VM service, so they cannot be intercepted automatically.
Forward them explicitly:

```dart
import 'dart:developer' as dev;

void myLog(String message, {String? name}) {
  dev.log(message, name: name ?? '');
  Critic.instance.captureLog(message, tag: name);
}
```

## Example

See the [example app](example/) for a complete working demo with Material 3 UI,
including a `package:logging` wiring example.

## License

See [LICENSE](LICENSE) for details.
