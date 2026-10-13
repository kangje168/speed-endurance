# Connect IQ submission

## Prepared identity

- App: Speed Endurance, version 1.0.0.
- Publisher: kangje168.
- Support email: dukang668@gmail.com.
- App ID: `a5b8657e9da44c87b9b0177f94c368a1`.
- Signing key: `.private/developer_key.der`. Keep a secure backup. Never regenerate it for updates.

## Build the submission package

1. Use Garmin SDK Manager to sign in and download the four Forerunner 255 device definitions and required fonts.
2. Start the Connect IQ simulator from the installed SDK.
3. Run the release script. It builds all four target models, runs native tests on each, then exports the multi-device `.iq` package:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\release.ps1
```

The script uses the project-local SDK and Java by default. Optional `-SdkBin`, `-JavaExecutable`, and `-DeveloperKey` arguments select existing tools. The execution-policy flag applies only to this process; it does not change system policy.

Outputs are `release/SpeedEndurance-1.0.0.iq`, native test logs, and `release/build-report.json` with the package SHA-256 and per-device results. A package has not been produced until this script succeeds. Build output from a temporary toolchain smoke check is not a supported-device release.

## Finish release validation

- Complete `HARDWARE-TESTS.md` on physical hardware.
- Capture actual simulator/watch screenshots from the final build.
- Review `STORE-LISTING.md`, `PRIVACY.md`, and `privacy.html`.
- Host `privacy.html` at a publicly accessible HTTPS URL and verify that it is reachable without login.
  Published and verified on October 13, 2026: https://kangje168.github.io/speed-endurance-privacy/ (HTTP 200, correct policy title and support email). Maintenance files and instructions are in `github-pages/` and `GITHUB-PAGES.md`.
- Back up the signing key securely outside the source repository.

## Submit

Follow [Garmin's submission instructions](https://developer.garmin.com/connect-iq/submit-an-app/) and use your own Garmin developer account. Upload the `.iq` package, enter version 1.0.0, paste the prepared listing, add the icon and actual screenshots, and enter the public privacy-policy URL and support contact.

Review the final store preview before sending it for review. Garmin controls approval and publication; local export does not publish the application. No store upload or review submission has been performed by this project setup.

## Later updates

Keep the same application ID and signing key. Update `metadata.json`, the listing's release notes, and the relevant source/resources; repeat the build, tests, hardware checks, and export. Increment the version entered in the developer dashboard.
