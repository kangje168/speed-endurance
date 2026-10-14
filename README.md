# Garmin 255 Speed Endurance

Speed Endurance is a standalone Connect IQ watch app for the Forerunner 255, 255 Music, 255S, and 255S Music. Publisher: **kangje168**. Support: **dukang668@gmail.com**. The interface is in English.

**Release candidate 1.0.1 adds a relaxed GPS start gate and a heart-rate dashboard. See release/VALIDATION.md for updated validation.** The package manifest and all four device binaries have been inspected; the package contains no private keys or tool files.

The store upload package is [release/SpeedEndurance-1.0.1.iq](release/SpeedEndurance-1.0.1.iq). Build evidence is in [release/build-report.json](release/build-report.json). The [public privacy policy](https://kangje168.github.io/speed-endurance-privacy/) is live and verified. Physical-watch validation, final screenshots, and store submission remain pending.

## Training rules

- Target pace is measured in minutes per kilometer. There are 12 levels: 5:30, 5:15, 5:00, 4:45, 4:30, 4:15, 4:00, 3:45, 3:30, 3:15, 3:00, and 2:45.
- Once GPS data is valid, press START to begin a training interval. Running slower than the target starts a 60-second countdown; meeting or exceeding the target speed resets it. After 60 continuous seconds below the target speed, the app stops the interval timer, alerts with vibration and sound, and enters rest mode.
- Zero speed with valid GPS data counts as below target. Invalid GPS data or data that has not updated for more than 2.5 seconds resets the below-target countdown. The interval timer continues, but that interval cannot set a best record.
- This version uses the device's instantaneous speed without additional pace smoothing. GPS pace behavior and alert timing require validation during actual runs.
- Each pace level has its own best record: the longest interval duration from start to stop, **including the final 60 seconds below target speed**. An interval qualifies only if the runner meets the target at least once and no invalid data is detected during the interval. Valid intervals stopped manually can also set records.
- Rest timing starts automatically when an interval stops. The app alerts once after rest exceeds 3 minutes (checked every second, typically at 3:01), then saves and exits when rest reaches 5:00.
- During rest, you can change the target pace and press START to begin the next interval. The target is locked while running.
- The watch stores each interval's target pace, duration, stop reason, date, and subsequent rest duration. It keeps the latest 40 intervals; best records are stored separately. Rest duration is saved every 10 seconds and on normal exit. Power loss or a crash may lose rest data since the most recent checkpoint.
- Each use of the app records one FIT running activity. Ending an interval creates a lap, and FIT recording is paused during rest. Garmin Connect display behavior requires device validation; rest durations are recorded in the app's history.

## Controls

| Button | Action |
| --- | --- |
| START / STOP (top right) | Start training; manually end the current interval while running; start the next interval during rest |
| UP / DOWN (middle/bottom left) | Switch pages while running; adjust pace before running or during rest; browse history |
| Hold UP (menu) | Show or hide history; training continues timing in the background |
| BACK / LAP (bottom right) | End the current interval while running; save and exit from rest or pace selection; return from history |

The main screen shows the target pace, running or rest timer, instantaneous pace or below-target countdown, and the best record for the selected pace. History shows `Run` and `Rest` durations.

## Build and installation

The current workspace already has the SDK, Java, device definitions, and an RSA 4096 signing key. Tools live in `.tools/`; the signing key is `.private/developer_key.der`. Both directories are excluded from source control. **Back up this key securely: future updates to the same store app require the same key and app ID.**

Build a watch-installable release binary:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\build.ps1 -Device fr255 -Release
```

The output is `bin/SpeedEndurance-fr255.prg`. Use `fr255m` for the Music version, `fr255s` for the 255S, and `fr255sm` for the 255S Music. All four installable release binaries are present in `bin/`; files ending in `-tests.prg` are test builds, not regular installations.

Validate the app in the simulator and on hardware before regular use. To sideload a build, copy the matching `.prg` file to the watch's `GARMIN/APPS` folder over USB, safely disconnect, and open `Speed Endurance` from the activity list. Access to the USB filesystem depends on your operating system and the watch's connection mode.

### Reproduce the toolchain on Windows

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\setup.ps1
```

The setup script downloads pinned official SDK/Java archives, verifies SHA-256 checksums, and extracts them within the project. Use SDK Manager to sign in with your own Garmin account and install the four target device definitions and required fonts. Review [Garmin's SDK terms](https://developer.garmin.com/downloads/connect-iq/sdks/agreement.html) when installing the SDK.

Only on a new project without an existing release key, add `-GenerateKey` to create a key. For this project, restore the original key from backup instead. The script refuses to overwrite an existing key.

Build scripts accept `-SdkBin`, `-JavaExecutable`, and `-DeveloperKey` to use tools or a key at other paths. The execution-policy option applies only to the launched PowerShell process and does not change system policy.

### Export for Connect IQ

Start the Connect IQ simulator, then run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\release.ps1
```

This builds all four models, runs their complete native test suites, exports the signed multi-device `.iq` package, and checks its manifest and binaries. The report includes the package SHA-256 and test counts. On this Windows setup, the SDK test launcher returns exit code 1 even after an all-pass result; the release script requires an exact zero-failure/zero-error native summary and the expected test count, and records the launcher exit code.

Prepared store materials:

- [Store listing](release/STORE-LISTING.md): English description, controls, record rules, and release notes.
- [Privacy policy](release/PRIVACY.md) and [standalone privacy page](release/privacy.html): published at the [public HTTPS policy URL](https://kangje168.github.io/speed-endurance-privacy/).
- [Store icon](release/assets/store-icon-512.png): original artwork, with a 128px alternative.
- [Hardware acceptance tests](release/HARDWARE-TESTS.md).
- [Submission guide](release/SUBMISSION.md).

The generated package requires firmware 25.02 according to Garmin's current device definitions. Garmin's dashboard performs its own validation and review; exporting the package does not publish it.

## Validation

`tests/TrainingEngineTest.mc` contains 11 native Monkey C tests covering the 60-second stopping rule and its boundary, recovery at/above target, GPS loss, rest boundaries, zero speed, pace selection and locking, sampling gaps, manual stops after data gaps, and state reset for the next interval. `tests/PaceViewTest.mc` adds actual rendering of pace selection, running, rest, finished, empty history, and populated history screens.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\build.ps1 -Device fr255 -Tests
# Start the Connect IQ simulator, then run the monkeydo command printed by the script.
```

All 12 native tests passed on each of the four target simulators. XML parsing, PowerShell script syntax, archive checksum verification, and inspection of the exported IQ package also passed. An optional JavaScript adaptation of the pure engine tests is available via `node scripts/check-engine.mjs`; native Garmin results are the primary test evidence.

Rendering tests verify that drawing executes without runtime exceptions; they do not prove visual layout quality. Before public submission, complete physical-watch checks for text placement, GPS acquisition and loss, vibration and sound, physical buttons, FIT pause/resume and saving across multiple intervals, persistence, and five-minute automatic exit. Capture actual screenshots from the final build and use the verified public privacy-policy URL in the submission.

## API references

- [Position.Info](https://developer.garmin.com/connect-iq/api-docs/Toybox/Position/Info.html): speed and positioning accuracy.
- [ActivityRecording.Session](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityRecording/Session.html): start, stop, lap creation, and FIT saving.
- [Attention](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html): vibration and sound alerts.
- [System](https://developer.garmin.com/connect-iq/api-docs/Toybox/System.html): millisecond timing and application exit.

## Changes in 1.0.1

Starting requires a real position of at least poor quality updated within five seconds, but no speed sample. Countdown checks still require usable GPS quality and valid speed updated within 2.5 seconds. Weak or missing data suspends the countdown and disqualifies the interval from a personal best. Supported multi-band positioning is requested when available.

While running, UP or DOWN switches to a second dashboard: heart rate, interval time, total active time excluding rest, and clock time. Stale or unavailable heart rate displays --. Stopping returns to the first page. This dashboard uses Garmin sensor data; it is not the built-in Run application's screen.
