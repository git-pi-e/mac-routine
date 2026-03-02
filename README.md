# MacRoutine

A modular MacOS application that triggers work routines based on location and Wi-Fi conditions.

## Features

- **Wi-Fi Trigger**: Multi-SSID support (OR logic). Select from known networks or enter custom ones.
- **Location Trigger**: Geofencing with customizable radius. Search for locations via Nominatim (maps API).
- **Plug-and-Play Actions**: Execute macOS Shortcuts or custom shell scripts.
- **Auto-Revert**: Optional revert action when exiting the triggered condition.
- **Menu Bar UI**: Lightweight status bar app with quick controls.
- **Setup Wizard**: Beautiful CLI to configure your routines.

## Installation

### Prerequisites

- macOS 14.0 or later.
- Swift toolchain (Xcode or Command Line Tools).

### Building from source

1. Clone the repository:
   ```bash
   git clone https://github.com/git-pi-e/mac-routine.git
   cd mac-routine
   ```

2. Build the project:
   ```bash
   swift build -c release
   ```

The binary will be located at `.build/release/MacRoutine`.

## Usage

### 1. Setup a Routine

Run the setup wizard to create your first routine:

```bash
./.build/release/MacRoutine setup
```

Follow the prompts to:
- Name your routine.
- Select Wi-Fi networks (Multiple SSIDs supported).
- (Optional) Set a location radius.
- Select/Assign a macOS Shortcut for Trigger and (optional) Revert.

### 2. Run the App

Launch the application in daemon mode:

```bash
./.build/release/MacRoutine
```

The app will appear in your menu bar (⚡ icon).

### Distribution (Homebrew)

The project includes a GitHub Action to automatically publish/update a Homebrew formula on every release.
To use this, you must:
1. Create a [Personal Access Token (classic)](https://github.com/settings/tokens) with `public_repo` scope.
2. Add it as a secret named `HOMEBREW_TAP_TOKEN` in your repository settings (Settings > Secrets and variables > Actions).
3. Ensure you have a tap repository at `git-pi-e/homebrew-tap`.
