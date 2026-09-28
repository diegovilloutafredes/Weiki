# Weiki

Keep your Mac awake from the menu bar.

Weiki is a small macOS menu bar app that does what `caffeinate` does, from a menu instead of a terminal. It keeps the Mac awake indefinitely, for 15 minutes, 1 hour, or 2 hours, for any duration you type, or until an app quits.

## Features

- **Always visible.** The cup in the menu bar fills while Weiki keeps the Mac awake, next to ∞, the time left (for example `42m`), or the app it's waiting for.
- **Display on, or just the system.** "Keep Display On" decides whether the screen stays on too, or only the Mac stays awake while the screen sleeps.
- **Custom durations.** Type `45`, `45m`, `2h`, `1h30`, or `1:30`, and Weiki shows when the session would end before you start it.
- **Until an app quits.** Pick a running app, and the Mac stays awake until that app quits, even if it crashes. Useful for a long build, render, or download.
- **Only on AC power.** Turn it on and a session pauses while the Mac runs on battery, then picks up again when you plug it back in.
- **Notify when time's up.** Turn it on and Weiki posts a notification when a timed session runs out.
- **See what else keeps the Mac awake.** The menu lists the other apps and processes keeping the Mac awake, such as a video call or a `caffeinate`, and whether they keep the display on.
- **Nothing left behind.** A session ends on time, even if the Mac slept past the end, and quitting Weiki releases its hold right away.
- **Launch at Login.** Off until you turn it on in the menu; the checkmark always matches System Settings.

## Shortcuts

Weiki adds four actions to the Shortcuts app:

- **Keep Mac Awake**, indefinitely or for a duration from 1 minute to 24 hours
- **Keep Mac Awake Until App Quits**, for a running app
- **Turn Off Weiki**
- **Is Weiki Keeping the Mac Awake?**, which returns true or false

A session started from Shortcuts works like one started from the menu. Siri and Spotlight know "Keep my Mac awake with Weiki", "Turn off Weiki", and "Is Weiki on?" without any setup. To use a keyboard shortcut, add one to a shortcut in the Shortcuts app. On macOS 26 and later, a Shortcuts automation can run these actions at a time of day, when an app opens, when a display connects, or when a Focus starts. For example: when Keynote opens, keep the Mac awake until Keynote quits.

## How it works

Weiki creates IOKit power assertions directly, the same mechanism `caffeinate` uses. While a session is active, you can see its hold with:

```bash
pmset -g assertions | grep Weiki
```

## Requirements

macOS 15 or later. Building from source needs Xcode 26 or later and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

## Install

To install the latest release, or to update to it, run this in Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/diegovilloutafredes/Weiki/main/scripts/install.sh | bash
```

It downloads the latest release, replaces `/Applications/Weiki.app`, and opens it. If Weiki is running, it quits first, which ends its session.

You can also download `Weiki.dmg` or `Weiki.zip` from [Releases](https://github.com/diegovilloutafredes/Weiki/releases):

- **DMG:** open it and drag Weiki to Applications.
- **ZIP:** unzip it and double-click `install.command`. It copies Weiki into Applications, clears the quarantine flag, and opens it. If macOS blocks the script, run `bash install.command` in Terminal instead.

Weiki isn't signed with a Developer ID, so macOS blocks the first launch of a copy downloaded in a browser. Try to open it once, then click **Open Anyway** in System Settings > Privacy & Security, or clear the flag yourself with `xattr -dr com.apple.quarantine /Applications/Weiki.app`. The one-line installer avoids this.

## Build from source

```bash
brew install xcodegen
make run    # builds Weiki, installs it into /Applications, and launches it
make test   # runs the tests
```

## License

MIT. See [LICENSE](LICENSE).
