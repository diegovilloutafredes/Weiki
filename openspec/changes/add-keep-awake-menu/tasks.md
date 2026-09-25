# Tasks

## 1. Project scaffold

- [x] 1.1 Create `project.yml` per design Decision 10 (targets `Weiki` and `WeikiTests` hosted by the app; macOS 15.0; Swift 6; default MainActor isolation; generated Info.plist with `LSUIElement`; bundle ID `com.weiki.app`; ad-hoc signing). Also create `.gitignore` (`Weiki.xcodeproj/`, `build/`, `.DS_Store`, `xcuserdata/`) and a `Makefile` with `generate`, `build`, `run`, `test`, and `clean`, modeled on the author's other menu bar app. Verify that `make generate` creates `Weiki.xcodeproj` and that `git status` does not list it.
- [x] 1.2 Add a minimal `WeikiApp`: a `MenuBarExtra` in `.menu` style with the outlined cup icon and a "Quit Weiki" item. Verify that `make build` succeeds with no warnings, that `make test` passes with its one test (the app bundle is a menu bar agent; a test bundle with no sources can't load), and that `make run` shows the icon with no Dock icon and "Quit Weiki" exits.
- [x] 1.3 Write the project notes: what Weiki is, the `make` targets, the `openspec/` workflow, and using `xcrun swiftc` for scripts. Verify that every command they document runs as written.

## 2. Power assertion boundary

- [x] 2.1 Write the `@Suite(.serialized)` integration tests for `SystemPowerAssertions` before the implementation (design Decision 11). Cover display type, system type, the name "Weiki", details, timeout seconds with `TimeoutActionRelease`, no timeout for an indefinite hold, and removal after release, all read back through `IOPMCopyAssertionsByProcess`. Verify that the suite fails before 2.2.
- [x] 2.2 Implement `PowerAssertionService` and `SystemPowerAssertions` per design Decisions 2 and 3: the only file importing IOKit, with best-effort release. Verify that `make test` passes the 2.1 suite with no warnings.

## 3. Session controller

- [x] 3.1 Write `AwakeController` tests first, using a recording fake service and a throwaway `UserDefaults` suite. They cover every `keep-awake` scenario that doesn't need the real system:
  - launch is off
  - indefinite and timed starts (end time, timeout passed to the service)
  - a restart acquires the new hold before releasing the old one
  - turning off releases the hold
  - Keep Display On defaults to on and persists
  - a mode change during a session keeps the end time, passes the remaining time (not the original duration) as the new hold's timeout, and acquires before releasing
  - a mode change while off makes no service calls
  - a refused hold, when starting and when replacing, ends off with nothing held
  - a sub-second session ends on its own and releases its hold

  Verify that they fail before 3.2.
- [x] 3.2 Implement `AwakeController` per design Decisions 4 to 6, including the end loop that sleeps at most 60 seconds and re-reads the wall clock. Verify that `make test` passes with no warnings.
- [x] 3.3 Add the controller rules to the project notes: acquire before release; the end date is the source of truth and the system timeout only a safety net; release is best-effort. Verify that the text matches the code.

## 4. Status line

- [x] 4.1 Write tests first for the status-line function, using a fixed `now`, calendar, and locale. Cover off, indefinite, a same-day end in a 24-hour and a 12-hour locale, and an end on another day with the abbreviated weekday. Verify that they fail before 4.2.
- [x] 4.2 Implement the function per design Decision 9, building the strings with `String(localized:)`. Verify that the 4.1 tests pass.

## 5. Menu

- [x] 5.1 Build the menu per `specs/menu-bar-controls` (all of it except "Custom…", which comes in group 6):
  - the status line
  - "Turn Off", shown only while a session is active
  - a "Keep Awake For" section with "Indefinitely", "15 Minutes", "1 Hour", and "2 Hours"
  - a "Keep Display On" toggle
  - "Quit Weiki"
  - a cup icon that is filled or outlined according to the state

  Verify with `make run` and `pmset -g assertions`:
  - "15 Minutes" lists a `Weiki` hold of type `PreventUserIdleDisplaySleep` with a timeout of about 900 seconds, and the icon fills.
  - Unchecking Keep Display On switches the hold to `PreventUserIdleSystemSleep` with the same end time.
  - "Turn Off" removes the hold, and the icon goes back to outlined.
- [x] 5.2 Verify quitting and relaunching:
  - With an indefinite session active, "Quit Weiki" leaves no `Weiki` line in `pmset -g assertions`.
  - After relaunching, the icon is outlined, the status line reads "Weiki is off", and Keep Display On keeps its last value.
  - While a session is active, Activity Monitor's Energy tab shows Weiki preventing sleep.
- [x] 5.3 Add the menu constraints to the project notes: the label shows only the icon, the status line is computed when the menu opens, and there is no countdown. Verify that the text matches the code. (Superseded by group 8: the label now also shows "∞" or the time left, counting down; the menu's status line still shows the end time.)

## 6. Custom duration window

- [x] 6.1 Add the `Window` scene and the "Custom…" item per design Decision 8. The window has hours from 0 to 24 and minutes from 0 to 55 in 5-minute steps (superseded by 9.1: 1-minute steps, 0 to 59), and opens at 0 hours 30 minutes. Start is disabled at 0:00; otherwise it starts the session and closes the window. Verify:
  - No window appears at launch.
  - "Custom…" brings the window in front of other apps. If it doesn't, add `orderFrontRegardless()` and record the answer under Open Questions in `design.md`.
  - 1 hour 30 minutes shows a timeout of about 5400 seconds in `pmset -g assertions`.
  - Closing the window without clicking Start changes nothing.
- [x] 6.2 Add the window details to the project notes: suppressed at launch, activated after opening. Verify that the text matches the code.

## 7. Integration

- [x] 7.1 Run `make clean generate test run`. Then walk through every scenario in `specs/keep-awake/spec.md` and `specs/menu-bar-controls/spec.md`, checking each against the running app and `pmset -g assertions`. Script this through System Events with `osascript` if Accessibility access is granted, and do it by hand otherwise.
  - Refused-hold scenarios are covered only by the 3.1 unit tests.
  - The sleep-past-the-end-time scenario needs a closed lid, so it moved to 7.3.

  Record any deviation and fix it.
- [x] 7.2 Review the Swift sources and fix the confirmed findings. Verify that `make test` still passes and that `openspec validate add-keep-awake-menu --strict` succeeds.
- [ ] 7.3 By hand (needs a person): start a 1-minute custom session, put the Mac to sleep (Apple menu > Sleep, or close the lid with no external display) for more than 1 minute, then wake it. Also in the Custom window: type a duration and press Return to start it; reopen it and press Escape to close it without changes. Verify that within a minute of waking the icon is outlined, the status line reads "Weiki is off", and `pmset -g assertions` lists no Weiki hold.

## 8. Active option and time left in the menu bar

- [x] 8.1 Write tests first:
  - the time-left text in `en_US`: 1 minute is "1m", 42 minutes "42m", 60 minutes "1h", 65 minutes "1h 5m", 1495 minutes "24h 55m"
  - `activeOption`: set by each option, replaced by the next, cleared by Turn Off, the timer ending, and a refused hold, and kept by a mode change
  - `minutesLeft`: rounded up at the start (41 min 10 s is 42), dropping by one at each minute with the injected clock and sleep, each wait at most 60 s, and nil when off or indefinite

  Verify that they fail before 8.2.
- [x] 8.2 Implement `DurationOption`, `start(_:)`, `activeOption`, `minutesLeft`, and the minute-aligned end loop per design Decisions 5 and 5a, moving the existing tests from `start(for:)` to `start(_:)`. Verify that `make test` passes with no warnings.
- [x] 8.3 Make the duration items checkmark `Toggle`s and draw the menu bar label as one template image (cup plus "∞" or the time left) per design Decision 7. Verify in the app through System Events and screenshots:
  - after "Indefinitely", only it has a ✓ and the menu bar shows the filled cup and "∞"
  - after "15 Minutes", the ✓ moves and the menu bar shows "15m", then "14m" a minute later
  - a custom session checks "Custom…", and a mode change keeps the ✓
  - Turn Off clears the ✓ and leaves only the outlined cup
  - VoiceOver still reads "Weiki, Awake until …"
- [x] 8.4 Update the project notes for `DurationOption`, `activeOption`, `minutesLeft`, and the composed template label. Verify that the text matches the code.
- [x] 8.5 Rerun the scenario walkthrough, extended with the ✓ and menu bar text checks, and run `openspec validate add-keep-awake-menu --strict`. Verify that both pass.

## 9. One-minute steps in the Custom window

- [x] 9.1 Change the Custom window's minutes picker to 0 to 59 in 1-minute steps. (Superseded by 11.3: the window now has one text field that accepts any minute count.) Verify in the app through System Events:
  - the minutes pop-up lists 0 to 59 and the window still opens at 0 hours 30 minutes
  - 0 hours 1 minute starts a session with a timeout of about 60 seconds, and the menu bar shows "1m"
  - about a minute later the session ends by itself: outlined cup, "Weiki is off", no Weiki hold
- [x] 9.2 Update the project notes for the new range. Verify that `make test` passes and `openspec validate add-keep-awake-menu --strict` succeeds.

## 10. Custom window under the Weiki icon

- [x] 10.1 Probe (throwaway) which coordinate system `WindowPlacement` and the display's `visibleRect` use, compared with `NSEvent.mouseLocation`, and record the answer in design Decision 8. Verify by the placed window's frame as reported through Accessibility.
- [x] 10.2 Write tests first for the placement function: centered on a pointer under the menu bar; clamped at the left and right edges; top just below the menu bar; top-right when the pointer is far from the menu bar or missing. Verify that they fail before 10.3.
- [x] 10.3 Implement the function and wire it with `.defaultWindowPlacement`. Verify that `make test` passes with no warnings, and in the app:
  - with a real click on "Custom…", the window's top is at the menu bar's bottom and it overlaps the Weiki icon horizontally
  - when opened with the pointer elsewhere, it appears at the top-right below the menu bar
  - within the same launch it reopens where it was last, including after being moved (standard macOS behavior, chosen over re-placing it on every opening)
- [x] 10.4 Update the project notes. Verify that `openspec validate add-keep-awake-menu --strict` succeeds.

## 11. Typed custom duration

- [x] 11.1 Write tests first, with a fixed calendar and locale:
  - `parseDuration` valid inputs: "45", "45m", "45 min", "90", "2h", "1h30", "1h 30m", "1:30", "0:45", "24h", " 5m "
  - `parseDuration` invalid inputs: "", "abc", "0", "0m", "25h", "24h1m", "1h60", "1:60", "1:5", "-5", "1.5h"
  - the line below the field: "1h30" at 14:00 shows "Until 15:30"; "24h" on a Thursday at 10:00 shows "Until Fri 10:00"; "abc" shows the hint

  Verify that they fail before 11.2.
- [x] 11.2 Implement `parseDuration` and the line below the field. Verify that `make test` passes with no warnings.
- [x] 11.3 Replace the pickers with the text field, the line below it, Start (the default button, disabled while the text is invalid), and Escape. The field opens with "30m" and has focus. Verify in the app through System Events:
  - the field opens with "30m", and the line shows the end time 30 minutes from now
  - entering "1h30" updates the line, and Start starts a session of about 5400 seconds
  - "abc" shows the hint and disables Start
  - "1" starts a session, and the menu bar shows "1m"

  Check Return and Escape by hand, because scripted keystrokes go to the frontmost app, not to Weiki.
- [x] 11.4 Update the project notes and rerun the scenario walkthrough with typed durations. Verify that `openspec validate add-keep-awake-menu --strict` succeeds.
