# TartUI

TartUI is a small, native macOS app for viewing Tart images and managing local virtual machines.

Some early interaction ideas were inspired by [TartDesk](https://github.com/mohnya-org/TartDesk).

English · [繁體中文](README.zh-Hant.md)

## What it manages

- **Images** lists downloaded OCI images from `tart list --source oci`. Images are sources, so they never display a running or stopped state.
- **Virtual Machines** lists local instances from `tart list --source local`. Runtime actions and status belong only to this section.
- Pull OCI images with transfer concurrency and insecure-registry options.
- Create VMs by cloning an OCI image or local VM, restoring a macOS IPSW, creating an empty Linux disk, or importing a `.tvm` archive.
- Configure clone pruning, disk capacity, RAW/ASIF format, CPU, memory, display, display refitting, disk replacement, MAC regeneration, and macOS serial regeneration.
- Run VMs in a window, headless, over Screen Sharing/VNC, or on a serial console, with Tart's network, device, shared-directory, additional-disk, Rosetta, and root-disk options.
- Manage shared folders and additional disks as editable rows, with native file and folder pickers plus read-only, mount-tag, and synchronization controls.
- Start immediately with **Run**, which remembers the last successful run options separately for each VM, or use **Run With Options…** to review and replace them.
- Stop, suspend, rename, export, reveal, and delete local VMs.
- Inspect IP resolution, guest network interfaces, OS/kernel/architecture/uptime, guest disk and memory usage, host allocation, and the local VM path.
- Open a normal `ssh user@address` command in Terminal or copy it to the clipboard.
- Use the interface in English or Traditional Chinese through Apple's native per-app language support.

The app invokes the existing Tart CLI directly and does not install or modify Tart.

Guest operating-system and usage details require [tart-guest-agent](https://github.com/cirruslabs/tart-guest-agent) in the running VM. DHCP and ARP IP lookup remain available without it.

## Safety boundaries

TartUI never edits `~/.ssh/config`, `~/.ssh/known_hosts`, `StrictHostKeyChecking`, host networking, or Tart VM disk contents merely to display information. SSH uses the host's normal OpenSSH trust policy.

## Requirements

- macOS 15 or later
- Xcode 26 or later
- Tart installed separately. TartUI automatically checks `/opt/homebrew/bin/tart` and `/usr/local/bin/tart`; another executable can be selected in Settings.

## Development

```bash
make format
make check
```

You can also open `TartUI.xcodeproj`, select the `TartUI` scheme, and run the macOS target. Pass `--force-light`, `--force-dark`, or `--sidebar-hidden` as launch arguments for visual verification.

The project uses Swift 6, SwiftUI, Observation, and an Apple String Catalog. Tart CLI execution, argument encoding, run-option persistence, and host integration live in `Services`; views do not execute Tart commands directly. Native `swift-format` is the required formatter and baseline linter. A SwiftLint configuration is also included for contributors who use it.

The app is intentionally not sandboxed because it launches the locally installed Tart executable. Distribution should add an explicit signing and notarization configuration before release.

## Project structure

- `TartUI/App` — app scenes, navigation, and Settings
- `TartUI/Features` — image and virtual-machine interfaces
- `TartUI/ViewModels` — observable presentation state and use-case orchestration
- `TartUI/Services` — Tart CLI, persistence, argument codecs, and macOS integrations
- `TartUI/Models` — domain and option models
- `TartUI/Shared` — reusable SwiftUI components

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md), [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), and [SECURITY.md](SECURITY.md).

## License

TartUI is available under the [MIT License](LICENSE). Tart and tart-guest-agent are external projects and retain their own licenses; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). TartUI is an independent project and is not affiliated with or endorsed by OpenAI or Cirrus Labs.
