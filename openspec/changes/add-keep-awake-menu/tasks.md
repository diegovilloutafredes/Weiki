# Tasks

## 1. Project scaffold

- [ ] 1.1 Create `project.yml` per design Decision 10 (targets `Weiki` and `WeikiTests` hosted by the app; macOS 15.0; Swift 6; default MainActor isolation; generated Info.plist with `LSUIElement`; bundle ID `com.weiki.app`; ad-hoc signing). Also create `.gitignore` (`Weiki.xcodeproj/`, `build/`, `.DS_Store`, `xcuserdata/`) and a `Makefile` with `generate`, `build`, `run`, `test`, and `clean`, modeled on the author's other menu bar app. Verify that `make generate` creates `Weiki.xcodeproj` and that `git status` does not list it.
- [ ] 1.2 Add a minimal `WeikiApp`: a `MenuBarExtra` in `.menu` style with the outlined cup icon and a "Quit Weiki" item. Verify that `make build` succeeds with no warnings, that `make test` passes with no tests yet, and that `make run` shows the icon with no Dock icon and "Quit Weiki" exits.
- [ ] 1.3 Write the project notes: what Weiki is, the `make` targets, the `openspec/` workflow, and using `xcrun swiftc` for scripts. Verify that every command they document runs as written.

## 2. Power assertion boundary

- [ ] 2.1 Write the `@Suite(.serialized)` integration tests for `SystemPowerAssertions` before the implementation (design Decision 11). Cover display type, system type, the name "Weiki", details, timeout seconds with `TimeoutActionRelease`, no timeout for an indefinite hold, and removal after release, all read back through `IOPMCopyAssertionsByProcess`. Verify that the suite fails before 2.2.
- [ ] 2.2 Implement `PowerAssertionService` and `SystemPowerAssertions` per design Decisions 2 and 3: the only file importing IOKit, with best-effort release. Verify that `make test` passes the 2.1 suite with no warnings.

## 3. Session controller

- [ ] 3.1 Write `AwakeController` tests first, using a recording fake service and a throwaway `UserDefaults` suite. They cover every `keep-awake` scenario that doesn't need the real system:
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
- [ ] 3.2 Implement `AwakeController` per design Decisions 4 to 6, including the end loop that sleeps at most 60 seconds and re-reads the wall clock. Verify that `make test` passes with no warnings.
- [ ] 3.3 Add the controller rules to the project notes: acquire before release; the end date is the source of truth and the system timeout only a safety net; release is best-effort. Verify that the text matches the code.

## 4. Status line

- [ ] 4.1 Write tests first for the status-line function, using a fixed `now`, calendar, and locale. Cover off, indefinite, a same-day end in a 24-hour and a 12-hour locale, and an end on another day with the abbreviated weekday. Verify that they fail before 4.2.
- [ ] 4.2 Implement the function per design Decision 9, building the strings with `String(localized:)`. Verify that the 4.1 tests pass.

## 5. Menu

- [ ] 5.1 Build the menu per `specs/menu-bar-controls` (all of it except "Custom…", which comes in group 6):
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
- [ ] 5.2 Verify quitting and relaunching:
  - With an indefinite session active, "Quit Weiki" leaves no `Weiki` line in `pmset -g assertions`.
  - After relaunching, the icon is outlined, the status line reads "Weiki is off", and Keep Display On keeps its last value.
  - While a session is active, Activity Monitor's Energy tab shows Weiki preventing sleep.
- [ ] 5.3 Add the menu constraints to the project notes: the label shows only the icon, the status line is computed when the menu opens, and there is no countdown. Verify that the text matches the code.

## 6. Custom duration window

- [ ] 6.1 Add the `Window` scene and the "Custom…" item per design Decision 8. The window has hours from 0 to 24 and minutes from 0 to 55 in 5-minute steps, and opens at 0 hours 30 minutes. Start is disabled at 0:00; otherwise it starts the session and closes the window. Verify:
  - No window appears at launch.
  - "Custom…" brings the window in front of other apps. If it doesn't, add `orderFrontRegardless()` and record the answer under Open Questions in `design.md`.
  - 1 hour 30 minutes shows a timeout of about 5400 seconds in `pmset -g assertions`.
  - Closing the window without clicking Start changes nothing.
- [ ] 6.2 Add the window details to the project notes: suppressed at launch, activated after opening. Verify that the text matches the code.

## 7. Integration

- [ ] 7.1 Run `make clean generate test run`. Then walk through every scenario in `specs/keep-awake/spec.md` and `specs/menu-bar-controls/spec.md`, checking each against the running app and `pmset -g assertions`. Script this through System Events with `osascript` if Accessibility access is granted, and do it by hand otherwise.
  - Refused-hold scenarios are covered only by the 3.1 unit tests.
  - Check the sleep-past-the-end-time scenario by hand with a 5-minute custom session and a closed lid.

  Record any deviation and fix it.
- [ ] 7.2 Review the Swift sources and fix the confirmed findings. Verify that `make test` still passes and that `openspec validate add-keep-awake-menu --strict` succeeds.
