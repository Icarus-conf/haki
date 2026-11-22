# Contributing to Haki

Thanks for wanting to help. Bug reports, fixes, translations, design polish and docs are all welcome.

## Ways to help

- **Report a bug** using the bug template in Issues. Steps to reproduce and your platform help a lot.
- **Suggest a feature** using the feature template. Explain the problem first, then your idea.
- **Pick up an issue** labelled `good first issue` or `help wanted`. Comment on it first so two people don't do the same work.
- **Security problems:** please follow [SECURITY.md](SECURITY.md), not public issues.

## Getting set up

Follow [Run it locally](README.md#run-it-locally) in the README. In short:

```bash
cd haki-backend && cp .env.example .env    # fill in the secrets
docker compose up -d --build
cd ../haki_mobile && flutter pub get && flutter run
```

## Before you open a pull request

Run the checks for the parts you touched:

```bash
# App
cd haki_mobile
flutter analyze
flutter test

# Backend (with the Docker stack running)
cd haki-backend
npx tsc --noEmit
node scripts/smoke-test.js

# Dashboard
cd haki-dashboard
npx tsc --noEmit
```

If you change freezed models in the app, regenerate the code:

```bash
cd haki_mobile && dart run build_runner build -d
```

## How the code is organised

- **App (`haki_mobile/lib`):** each feature has a `view/` folder (widgets) and a `view_model/` folder (a Cubit with a freezed state). Services in `lib/services` talk to the API, the socket and the crypto layer. Use `HakiColors`, `HakiText` and `HakiIcons` from `lib/core/theme` instead of raw colours or Material icons.
- **Backend (`haki-backend/src`):** one NestJS module per area (auth, chat, groups, stories, feed, admin). Any new endpoint that touches user content should store **ciphertext only**. If the server needs a value in clear, say why in a comment.
- **Dashboard (`haki-dashboard/src/app/dashboard`):** one file per page. It must never show message content, only counts and timestamps.

## Rules for crypto changes

Changes to encryption, key handling or linking get extra review:

- Explain the threat you're addressing and what changes for existing users.
- Never log keys, plaintext or decrypted media.
- Keep old data readable, or describe the migration.

## Pull request checklist

- One focused change per pull request.
- Write the description for someone who hasn't seen the code: what changes for users, and how you tested it.
- Add screenshots for UI changes. Include a narrow phone and a wide screen if layout changed.
- New user-facing text: short, plain, sentence case.

By contributing, you agree that your contributions are licensed under the [AGPL-3.0](LICENSE).
