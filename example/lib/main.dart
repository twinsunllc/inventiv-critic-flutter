import 'dart:io';

import 'package:flutter/material.dart';

import 'package:inventiv_critic_flutter/critic.dart';
import 'package:inventiv_critic_flutter/model/bug_report.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  TextEditingController _descriptionController = TextEditingController(),
      _reproduceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Critic().initialize('gJ44GxttrahyVBFs4k3jb8T1');
  }

  void _submitReport(BuildContext context, {bool withFile = false}) async {
    BugReport report = BugReport.create(
        description: _descriptionController.text,
        stepsToReproduce: _reproduceController.text);

    if (withFile) {
      report.attachments = <Attachment>[];
      Directory dir = await getApplicationDocumentsDirectory();
      File file = File('${dir.path}/test.txt');
      File writtenFile =
          await file.writeAsString('Test file upload', mode: FileMode.write);
      report.attachments
          ?.add(Attachment(name: 'test file', path: writtenFile.path));
    }

    Critic().submitReport(report).then((BugReport successfulReport) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Bug Report has been filed, check console'),
      ));
      print(
          'Successfully logged!\ndescription: ${successfulReport.description}\nsteps to reproduce: ${successfulReport.stepsToReproduce}');
    }).catchError((Object error) {
      print(error.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Builder(
            builder: (context) => Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Text('Enter a description'),
                TextField(
                  controller: _descriptionController,
                ),
                Text('Enter steps to reproduce'),
                TextField(
                  controller: _reproduceController,
                ),
                MaterialButton(
                  color: Colors.grey,
                  onPressed: () {
                    _submitReport(context);
                  },
                  child: Text('Test Submit'),
                ),
                MaterialButton(
                  color: Colors.grey,
                  onPressed: () {
                    _submitReport(context, withFile: true);
                  },
                  child: Text('Test Submit with file'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
