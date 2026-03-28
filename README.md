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

## Example

See the [example app](example/) for a complete working demo with Material 3 UI.

## License

See [LICENSE](LICENSE) for details.
