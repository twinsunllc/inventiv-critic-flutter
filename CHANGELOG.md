## 1.0.0

First stable release with v3 API support, full test coverage, and modernized example app.

### API Changes (BREAKING)
- Migrate from v2 to v3 API (base URL `/api/v2` → `/api/v3`)
- `AppInstall.id` is now a `String` (UUID) instead of `int`
- `BugReport` now includes `id`, `device`, `app`, and `appVersion` fields from v3 response
- Add `AppVersion` model for v3 nested app version data
- `Attachment.fromJson` now reads `url` field (was `file_url` in v2)
- `Critic.initialize()` accepts an optional `baseUrl` parameter for custom API endpoints

### New Features
- Add `LogCapture` class: intercepts `print()` calls via Dart `Zone` and captures `FlutterError.onError` for automatic inclusion in bug reports
- Add `LogBuffer` ring buffer: fixed-capacity (default 500 entries) timestamped log store with bounded memory usage; oldest entries are evicted when full
- Add disk space and memory info to device status included in bug reports

### Bug Fixes
- Fix `App.fromJson` null safety for `name` and `platform` fields (CRITIC-236)

### Code Quality
- Rename `lib/modal/` to `lib/model/` (fix longstanding typo)
- Add `lib/inventiv_critic_flutter.dart` barrel exports file for a single clean import path
- Replace `@required` annotations with `required` keyword
- Remove `new` keyword usage per Dart style guide
- Replace `Completer`/`.then()` pattern in `Api.submitReport` with `async`/`await`
- Fix `Connectivity().checkConnectivity()` to handle `List<ConnectivityResult>` return type
- Add injectable HTTP client and device status provider for testability
- Add proper error handling for `submitReport` non-success responses
- Standardize log attachment filename to `console-logs.txt`

### Tests
- Add unit tests for model serialization (UUID string handling, int→String migration)
- Add unit tests for API request construction (PingRequest JSON, BugReportRequest fields)
- Add mock HTTP tests for ping and submitReport endpoints
- Add error handling tests (400, 401, 422, 500 responses, network errors)

### Example App
- Modernize example with Material 3 design
- Add initialization status indicator
- Add user identifier field
- Add proper loading and error states
- Update SDK constraints to >=3.7.0

### Infrastructure
- Add GitHub Actions CI workflow (flutter analyze + flutter test on PR/push)
- Add nightly security CI (package age check, actions security audit)
- Update repository URL to `inventiv-critic-flutter`

## 0.5.0

**BREAKING:** Minimum Dart SDK raised from 2.12.0 to 3.7.0. This is required by the
updated plus packages (connectivity_plus 7.x, device_info_plus 12.x, package_info_plus 9.x,
battery_plus 7.x), which all require Dart >=3.7.0.

Update Android toolchain (AGP 8.12.1, Gradle 8.13, Kotlin 2.2.0).

## 0.4.0

Updated dependencies and gradle version.

## 0.3.1

File size parsing toString fix.

## 0.3.0

Upgraded using Flutter 3.16.2.
Upgraded Gradle.
Upgraded all package dependencies.

## 0.2.0

Update to null safety

## 0.1.0

Update dependencies to allow using flutter 3.7

## 0.0.8

Remove dio lib
Update http library to support 0.12.x / 0.13.x

## 0.0.7

Upgraded all dependencies that were causing issues with newest Flutter versions (1.17.x).

## 0.0.5

Multiple attachments can be uploaded properly. Add battery and network connection to device status.

## 0.0.4

Added attachment support.

## 0.0.2

Cleaned up readme files for better published documents.

## 0.0.1

Initial version of the Critic integration. Supports bug reporting with custom description and steps to reproduce. All device platform information is gathered as well.
