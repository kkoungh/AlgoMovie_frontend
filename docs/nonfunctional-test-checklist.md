# Frontend Nonfunctional Test Checklist

This checklist covers frontend nonfunctional requirements that need browser, deployment, or CI validation in addition to Flutter widget tests.

## Automated Flutter Checks

- `test/nonfunctional/ui_performance_test.dart`
  - NFR-03: key screens render with mock data under 2 seconds in widget tests.
  - NFR-07: deployed API URL examples use HTTPS.
- `test/nonfunctional/usability_flow_test.dart`
  - NFR-11: a new user can complete mock onboarding and see a first recommendation.
  - NFR-12: UI remains usable when recommendation data is empty or cached dependencies are unavailable.
  - NFR-13/NFR-15: lint and coverage expectations are captured as project checks.

These tests use fake providers and mock data. They do not call the backend.

## NFR-03: Chrome Lighthouse FCP Measurement

Use Flutter web build against a local or staging deployment.

```bash
flutter build web
```

Serve the build with a static server, then run Lighthouse in Chrome DevTools:

1. Open Chrome DevTools.
2. Select the Lighthouse tab.
3. Choose Performance.
4. Run against the first route users see.
5. Confirm First Contentful Paint is under 2 seconds.

Record:

- Browser version
- Device/network profile
- FCP value
- Build mode and commit hash

## NFR-07: HTTPS Verification

Check the deployed frontend API configuration and browser network panel:

1. Open the deployed frontend over `https://`.
2. Open Chrome DevTools Network tab.
3. Trigger login, movie list, search, and recommendation calls.
4. Confirm every API request URL starts with `https://`.
5. Confirm there is no mixed-content warning in the Console tab.

Optional command-line check:

```bash
curl -I https://<frontend-host>
```

Pass criteria:

- Frontend is served through HTTPS.
- API requests use HTTPS.
- HTTP traffic redirects to HTTPS or is blocked.

## NFR-11: First Recommendation Time

Manual flow:

1. Clear local browser storage or use a new incognito session.
2. Start a timer when the signup/onboarding screen is visible.
3. Register a new test user.
4. Select the required preferred genres.
5. Stop the timer when the first recommendation card is visible.

Pass criteria:

- First recommendation appears within 5 minutes.
- No real production account or production data is used unless explicitly approved.
- Record test environment, network condition, and recommendation backend state.

## NFR-12: Graceful Degradation

Manual flow:

1. Sign in with a test user.
2. Temporarily make the recommendation service unavailable in a staging environment.
3. Open the home screen.
4. Confirm the app shows an empty or fallback recommendation state instead of crashing.

Pass criteria:

- The backend falls back to persisted recommendations or an empty list.
- The frontend renders loading, empty, and error states without blocking navigation.

## NFR-13: Flutter Analyze

Run:

```bash
flutter analyze
```

Pass criteria:

- No analyzer errors.
- Warnings are reviewed and either fixed or documented.
- `flutter_lints` remains configured in `pubspec.yaml`.

## NFR-15: Flutter Test Coverage

Run:

```bash
flutter test --coverage
```

Coverage output:

- `coverage/lcov.info`

Recommended local summary tools:

```bash
genhtml coverage/lcov.info -o coverage/html
```

Pass criteria:

- Overall coverage target is 80% or higher.
- Gaps around user-critical flows are reviewed.
- `coverage/` remains ignored by Git.

## Notes

- Widget tests are mock-based and are not a replacement for browser FCP or deployment HTTPS checks.
- Do not read or print `.env`, API keys, or production server URLs during tests.
- Do not call the real backend from Flutter tests unless a dedicated integration environment has been approved.
