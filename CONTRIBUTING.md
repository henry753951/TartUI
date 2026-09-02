# Contributing to TartUI

Thank you for helping improve TartUI.

## Before opening a change

1. Check existing issues and keep each pull request focused.
2. Preserve the separation between SwiftUI views, app state, models, and services.
3. Do not weaken SSH host verification or silently change host networking.
4. Add English source strings through SwiftUI localization APIs and provide a
   Traditional Chinese translation in `TartUI/Localizable.xcstrings`.

## Local checks

```bash
make format
make check
```

`make check` runs native `swift-format` linting and a clean command-line build.
If SwiftLint is installed, also run `make lint-swiftlint`.

## Pull requests

Explain the user-visible change, testing performed, and any Tart CLI behavior
affected. Include light- and dark-mode screenshots for layout changes.
