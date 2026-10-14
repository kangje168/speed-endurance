# Release candidate 1.0.1 validation

Validation date: October 14, 2026.

## Toolchain

- Garmin Connect IQ SDK 9.2.0.
- Eclipse Temurin JDK 17.0.20.1+1, portable project-local installation.
- Garmin's downloaded device definitions and fonts.
- RSA 4096 developer signing key, PKCS#8 DER format, stored outside source control.
- SDK, Java, and SDK Manager archive SHA-256 checks passed.

## Native build and test results

| Device | Release compilation | Native simulator tests |
| --- | --- | --- |
| Forerunner 255 (`fr255`) | Passed, no app warnings | 13 passed, 0 failed, 0 errors |
| Forerunner 255 Music (`fr255m`) | Passed, no app warnings | 13 passed, 0 failed, 0 errors |
| Forerunner 255S (`fr255s`) | Passed, no app warnings | 13 passed, 0 failed, 0 errors |
| Forerunner 255S Music (`fr255sm`) | Passed, no app warnings | 13 passed, 0 failed, 0 errors |

The suite covers continuous slow-speed stopping, recovery and equality at the target, GPS loss, rest thresholds, zero speed, pace bounds and locking, missed samples, next-interval resets, record eligibility after a data gap, and rendering all application screen states without runtime exceptions. It includes 11 engine tests, one rendering test covering both running dashboards, and one GPS-start/page-navigation test.

The Windows SDK test launcher returned code 1 even for all-pass runs. The release gate checks the exact native summary (`passed=13, failed=0, errors=0`) and the expected test count, rather than treating that launcher exit code as proof of a failure or success. Raw native logs are retained in `build-logs/`.

## Exported package

- File: `SpeedEndurance-1.0.1.iq`.
- Exported using Garmin's compiler with package and release options.
- Container: Garmin IQ archive, 7z format.
- All four intended hardware part numbers have their corresponding program binaries.
- Application ID and RSA 4096 signature metadata checked.
- No private signing keys or project tool files are included.
- Current official definitions set minimum firmware to **25.02** for each model.
- Package hash and per-device results are recorded in `build-report.json`.

## Other checks

- Project XML parsing passed.
- PowerShell build/setup/release/run script syntax checks passed.
- Original store icon generated and visually inspected.
- English listing, privacy policy, standalone privacy HTML, and submission instructions prepared.
- Public privacy policy verified without authentication: https://kangje168.github.io/speed-endurance-privacy/ returned HTTP 200 with the expected title and support email on October 14, 2026.

## Pending before public release

- Physical-watch testing of outdoor GPS behavior, alarms, buttons, FIT saving/synchronization, multi-interval operation, and persisted records.
- Visual inspection of final screens on 240px/260px round displays and actual screenshots for the store.
- Review and submission through the publisher's own Garmin developer account.

Rendering tests confirm successful drawing operations, not that every label is visually well positioned. No physical-watch results, store upload, or Garmin approval are claimed.

## Hardware feedback changes

GPS start now accepts a fresh real position with at least poor quality without requiring speed. Reliable speed remains mandatory for slow-countdown checks. Multi-band GPS is requested where supported. A second running page displays heart rate, interval time, total active time, and clock time. These changes still require physical-watch validation; simulator tests do not demonstrate faster satellite acquisition.
