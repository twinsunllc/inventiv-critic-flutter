# inventiv-critic-flutter

A Flutter client SDK for submitting bug reports to [Inventiv Critic](https://critictracking.com/getting-started/). This SDK is designed for embedding in end-user apps and supports only report submission — administrative endpoints (listing reports, fetching individual reports, listing devices) are not included and should be accessed through the Critic web portal or server-side API instead.

## How to use

Step 1: Initialize the Critic library using your api key:

```
String key = 'your api key';
Critic().initialize(key);
```

Step 2: Create a new Bug Report using the .create const:

```
BugReport report = BugReport.create(
    description: 'description text',
    stepsToReproduce: 'steps to reproduce text',
);
```

Step 3: Attach a file, if necessary

```
File file = File('path to file');
report.attachments = <Attachment>[];
report.attachments!.add(Attachment(name: 'test file', path: file.path));
```

Step 4: Use the Critic() singleton to submit your BugReport (example using Futures):

```
Critic().submitReport(report).then(
    (BugReport successfulReport) {
      //success!
    }).catchError((Object error) {
      //failure
    });
```

Step 5: Review bugs submitted for your organization using [Critic's web portal](https://critic.inventiv.io)
