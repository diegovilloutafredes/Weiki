# Weiki

Keep your Mac awake from the menu bar.

Weiki is a small macOS menu bar app that does what `caffeinate` does, from a menu instead of a terminal. It keeps the Mac awake indefinitely, for 15 minutes, 1 hour, or 2 hours, or for any duration you type.

## Features

- **Always visible.** The cup in the menu bar fills while Weiki keeps the Mac awake, next to ∞ or the time left (for example `42m`).
- **Display on, or just the system.** "Keep Display On" decides whether the screen stays on too, or only the Mac stays awake while the screen sleeps.
- **Custom durations.** Type `45`, `45m`, `2h`, `1h30`, or `1:30`, and Weiki shows when the session would end before you start it.
- **Nothing left behind.** A session ends on time, even if the Mac slept past the end, and quitting Weiki releases its hold right away.
- **Launch at Login.** Off until you turn it on in the menu; the checkmark always matches System Settings.

## How it works

Weiki creates IOKit power assertions directly, the same mechanism `caffeinate` uses. While a session is active, you can see its hold with:

```bash
pmset -g assertions | grep Weiki
```

## Requirements

macOS 15 or later. Building from source needs Xcode 26 or later and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

## Build from source

```bash
brew install xcodegen
make run    # builds Weiki, installs it into /Applications, and launches it
make test   # runs the tests
```

## License

MIT. See [LICENSE](LICENSE).
