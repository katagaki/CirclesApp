# CirclesGo

CiRCLES for Android, a Jetpack Compose port of [CiRCLES for iOS](https://github.com/katagaki/CirclesApp) (usually checked out at `../CirclesApp`).

## Feature parity with iOS

When porting features from the iOS app, the iOS codebase is the reference for behavior, data models, and visuals. However, the following iOS features are **intentionally not implemented on Android** — do not port them:

- **My view** (circle.ms profile + participation planning)
- **Licenses / attributions view**
- **Share extension** (iOS-only concept)
- **Manual offline mode toggle** — Android handles offline automatically via reachability
- **TipKit tips and App Store review prompts** (iOS platform features)

## Conventions

- Commit messages are single-line, imperative ("Add X", "Fix Y").
- User-facing strings are localized in both `values/strings.xml` and `values-ja/strings.xml`.
- State classes live in `state/`, persisted caches in `data/local/` (SharedPreferences-JSON or files), API clients in `api/`.
- The favorites color palette (`WebCatalogColor`) mirrors the iOS 18-color palette in `../CirclesApp/RADiUS/WebCatalogColor.swift`.
