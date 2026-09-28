# Tasks

## 1. Before starting

- [ ] 1.1 Archive `add-keep-awake-menu` once its manual check (task 7.3) is done, so that `menu-bar-controls` exists as a main spec. Verify that `openspec validate add-session-conditions --strict` no longer reports that archive would refuse the `menu-bar-controls` delta.
- [x] 1.2 Check design Decision 3's assumption with a throwaway change: a SwiftUI `Menu` inside the `.menu`-style content becomes a submenu, and its items follow an `@Observable` list that changes while the menu is closed. Read the submenu's items through System Events before and after launching TextEdit. Record the answer under Open Questions in `design.md`. If it fails, switch the specs and design to the fallback before going on.

## 2. One session value

- [x] 2.1 Write the tests first:
  - `statusLine(now:)` for a session waiting for an app, and for paused indefinite, timed, and app sessions, in `en_US` with a 24-hour clock ("Awake until Xcode quits", "Paused on battery", "Paused on battery, until 14:35", "Paused on battery, until Xcode quits")
  - the label text for app names ("Xcode", and "Visual Stu…" for "Visual Studio Code")
  - the existing status line and time-left tests, unchanged

  Then change `State`, `SessionEnd`, and `DurationOption` per design Decision 1, and update every use of `State`. Verify that `make test` passes with no warnings.
- [x] 2.2 Update the project notes' Architecture section for the new `State`. Verify that the text matches the code.

## 3. Until an App Quits

- [x] 3.1 Write `AwakeController` tests first, with a fake `AppQuitWatcher`:
  - choosing an app starts `.appQuits` with no timeout and hold details that name the app
  - the app quitting turns the session off and clears `activeOption`
  - replacing or turning off the session stops the watch, and a late callback for the old app changes nothing
  - an app that has already terminated starts no session

  Then implement `AppQuitWatcher` and `SystemAppQuitWatcher` (design Decision 2). Verify that `make test` passes.
- [x] 3.2 Add `RunningApps` and the "Until an App Quits" submenu, with "No Apps Running" when the list is empty and a checkmark on the chosen app (design Decisions 3 and 7). Check with `make run`, System Events, and `pmset -g assertions`:
  - the submenu lists Dock apps in alphabetical order
  - it follows TextEdit launching and quitting
  - choosing TextEdit shows "Awake until TextEdit quits" and "TextEdit" in the menu bar, and holds with no timeout
  - quitting TextEdit turns the session off within a second
- [x] 3.3 Add `RunningApps`, the watcher, and the "follows the chosen process" rule to the project notes. Verify that the text matches the code.

## 4. Only on AC Power

- [x] 4.1 Write `AwakeController` tests first, with a fake `PowerSourceService`. They cover every scenario in `specs/ac-power-only`:
  - unplugging pauses (no hold, same end time)
  - starting on battery starts paused
  - turning the setting on while on battery pauses
  - a paused timed session still ends on time
  - plugging in resumes with the remaining time as the timeout
  - a mode change while paused creates no hold, and the resumed hold uses the new mode
  - a refused hold on resume ends off
  - turning the setting off resumes
  - the setting defaults to off and persists

  Then implement `PowerSourceService`, `SystemPowerSource`, and the pausing in `hold` (design Decisions 4 and 5). Verify that `make test` passes.
- [x] 4.2 Add the "Only on AC Power" item and the paused label and status line (design Decision 7). Verify with `make run` and `pmset -g assertions` on AC power that turning the setting on changes nothing while plugged in.
- [x] 4.3 By hand (needs a person with a laptop): with the setting on, unplug during a timed session and check that the cup is outlined, the status line reads "Paused on battery, until …", and `pmset -g assertions` lists no Weiki hold. Plug in again and check that one hold returns, with a timeout for the remaining time.

  Checked on a MacBook with a 1-hour session ending at 00:05, reading `pmset` 2 seconds after each change. On battery, turning the setting on paused the session. Plugging in resumed it: one hold, timeout 3216 s (the time left), filled cup. Unplugging paused it again: outlined cup, "Paused on battery, until Mon, 00:05", no Weiki hold, and the minutes kept counting down. Plugging in once more brought one hold back, timeout 2419 s.
- [x] 4.4 Add the power-source seam, the pausing rule, and `SystemPowerSource` as the second file that imports IOKit to the project notes. Verify that the text matches the code.

## 5. Notify When Time's Up

- [x] 5.1 Write the tests first, with a fake `NotificationService` and a throwaway `UserDefaults` suite:
  - the controller calls `onTimerEnd` once when a timed session runs out, including when the end passed during a long sleep of the test clock and while paused
  - it never calls it on Turn Off, a replacement, a refused hold, or the app quitting
  - `EndNotifications`: off by default and persisted; checked only when on and allowed; the first choice asks permission, and a decline leaves it unchecked; a choice after declining opens System Settings through a fake opener and leaves it unchecked

  Then implement `NotificationService`, `SystemNotificationService` with its delegate, and `EndNotifications` (design Decision 6). Verify that `make test` passes and never shows a permission prompt.
- [x] 5.2 Add the "Notify When Time's Up" item and connect `onTimerEnd` in `WeikiApp`. Verify with `make run`: turning it on shows macOS's prompt, and a 1-minute Custom session then posts "Weiki is off" when it ends.

  Choosing the item showed macOS's "“Weiki” Notifications" prompt (checked with a screenshot). Once notifications were allowed (see 5.3), choosing the item checked it and saved the choice. Two 1-minute Custom sessions each posted "Weiki is off", and the system log shows macOS presenting it as a banner, with no Focus suppression. With nothing touching Weiki, it posted about 4 seconds after the end: the system coalesces the end loop's timer. The hold itself was released on time by its IOKit timeout.
- [x] 5.3 By hand (needs a person): decline the prompt in a fresh setup, then choose the item again and check that System Settings opens at Weiki's notifications (or the Notifications page).

  Checked with notifications already declined for Weiki: choosing the item opened System Settings on Weiki's own page ("Allow notifications", switched off), and the item stayed unchecked. After switching notifications on there, choosing the item again checked it.

  The link itself works: `x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=com.weiki.app` opened System Settings on a "Weiki" page showing "Allow notifications" (macOS 27).
- [x] 5.4 Add the notification seam, the delegate rule, and "timers only" to the project notes. Verify that the text matches the code.

## 6. Integration

- [x] 6.1 Run `make clean generate test run`. Then walk through every scenario in the four spec deltas against the running app and `pmset -g assertions`. The scenarios that need a battery or a person were covered by 4.3 and 5.3. Record any deviation and fix it. Verify that `openspec validate add-session-conditions --strict` succeeds.

  Walked through with System Events, `pmset`, and menu bar screenshots on the installed build:
  - the submenu (Dock apps only, sorted, following TextEdit launching and quitting)
  - an app session replacing a timed one, and ending on quit and on `kill -9`
  - "∞", "15m", and "TextEdit" next to the cup
  - Only on AC Power on AC power, and its checkmark kept across a relaunch
  - the Custom window

  The battery and permission scenarios are the manual tasks 4.3, 5.2, and 5.3.
- [x] 6.2 Review the Swift sources and fix the confirmed findings. Verify that `make test` and `make build` pass with no warnings.
