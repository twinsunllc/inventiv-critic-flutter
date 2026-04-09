import 'dart:io';

import 'package:flutter/material.dart';
import 'package:inventiv_critic_flutter/critic.dart';
import 'package:inventiv_critic_flutter/model/bug_report.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

/// Wire [package:logging] into Critic so every log record appears in the
/// console-logs.txt attachment submitted with bug reports.
///
/// Note: [package:logging] is a dev dependency of this *example*; it is
/// intentionally NOT a dependency of the inventiv_critic_flutter SDK itself.
void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    Critic.instance.captureLog(
      record.message,
      level: record.level.name,
      tag: record.loggerName,
      timestamp: record.time,
    );
  });
}

final _log = Logger('CriticExample');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setupLogging();
  try {
    await Critic().initializeAndRun(
      'YOUR_API_TOKEN_HERE',
      () => runApp(const CriticExampleApp()),
    );
    _log.info('Critic initialized successfully');
  } catch (e) {
    _log.severe('Critic initialization failed: $e');
    runApp(CriticErrorApp(message: e.toString()));
  }
}

class CriticErrorApp extends StatelessWidget {
  final String message;

  const CriticErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Critic Example',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Initialization failed: $message',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class CriticExampleApp extends StatelessWidget {
  const CriticExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Critic Example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const CriticExamplePage(),
    );
  }
}

class CriticExamplePage extends StatefulWidget {
  const CriticExamplePage({super.key});

  @override
  State<CriticExamplePage> createState() => _CriticExamplePageState();
}

class _CriticExamplePageState extends State<CriticExamplePage> {
  final _descriptionController = TextEditingController();
  final _stepsController = TextEditingController();
  final _userIdController = TextEditingController();

  bool _submitting = false;

  Future<void> _submitReport({bool withAttachment = false}) async {
    if (_descriptionController.text.isEmpty) {
      _showSnackBar('Please enter a description');
      return;
    }

    setState(() => _submitting = true);

    final report = BugReport.create(
      description: _descriptionController.text,
      stepsToReproduce:
          _stepsController.text.isNotEmpty
              ? _stepsController.text
              : 'No steps provided',
      userIdentifier:
          _userIdController.text.isNotEmpty ? _userIdController.text : null,
    );

    if (withAttachment) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/sample_attachment.txt');
      await file.writeAsString(
        'Sample attachment created at ${DateTime.now().toIso8601String()}',
      );
      report.attachments = [
        Attachment(name: 'sample_attachment.txt', path: file.path),
      ];
    }

    try {
      _log.info('Submitting bug report…');
      final result = await Critic().submitReport(report);
      _log.info('Bug report submitted (ID: ${result.id})');
      _showSnackBar('Bug report submitted (ID: ${result.id})');
      _descriptionController.clear();
      _stepsController.clear();
      _userIdController.clear();
    } catch (e) {
      _log.warning('Bug report submission failed: $e');
      _showSnackBar('Submission failed: $e');
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _stepsController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Critic Example')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Submit a Bug Report',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the bug...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stepsController,
              decoration: const InputDecoration(
                labelText: 'Steps to Reproduce',
                hintText: '1. Open the app\n2. Tap on...\n3. Observe...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'User Identifier (optional)',
                hintText: 'e.g. user@example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submitting ? null : () => _submitReport(),
              icon:
                  _submitting
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.send),
              label: const Text('Submit Report'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed:
                  _submitting
                      ? null
                      : () => _submitReport(withAttachment: true),
              icon: const Icon(Icons.attach_file),
              label: const Text('Submit with Attachment'),
            ),
          ],
        ),
      ),
    );
  }
}
