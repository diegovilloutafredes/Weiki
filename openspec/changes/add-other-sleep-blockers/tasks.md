# Tasks

## 1. Before starting

- [ ] 1.1 Check design Decision 1 with a throwaway change: a counter in the status line, bumped on `NSMenu.didBeginTrackingNotification`. Read the status line through System Events on three openings. Record under Open Questions in `design.md` whether each opening shows its own count. If they don't, switch the design to the fallback before going on.

## 2. What counts

- [ ] 2.1 Write the `SleepBlockers.list(from:name:excluding:)` tests first, with literal assertions:
  - each counted type is listed (display and system)
  - ignored types, assertions that aren't on, Weiki's process, and `powerd` are left out
  - a process with both kinds reads as keeping the display on
  - two processes with one name are listed once
  - the order follows `localizedStandardCompare`

  Then implement it (design Decision 2). Verify that `make test` passes.
- [ ] 2.2 Write the serialized integration test first: a hold made with `SystemPowerAssertions` shows up in `processAssertions()` under this process, with its type, name, and level on. Then implement `processAssertions()` and the process naming (design Decision 3). Verify that `make test` passes.

## 3. The menu section

- [ ] 3.1 Add the `SleepBlockers` model, its refresh (design Decisions 1 and 4), and the "Also Keeping the Mac Awake" section. Verify with `make run`, System Events, and `caffeinate` every scenario in `specs/other-sleep-blockers`:
  - `caffeinate -i` and `caffeinate -d` read correctly
  - two `caffeinate -i` runs show one item
  - the section is absent with only the system's bookkeeping, and during a Weiki session with nothing else running
  - a `caffeinate` started or ended since the menu last opened is current at the next opening
- [ ] 3.2 Add the section, the refresh on open, and the counting rule to the project notes, and a line to the README's Features. Verify that the text matches the code and that both pre-push checks print nothing.

## 4. Integration

- [ ] 4.1 Run `make clean generate test run`, walk through the scenarios again, and review the new Swift code, fixing the confirmed findings. Verify that `openspec validate add-other-sleep-blockers --strict` succeeds and that `make build` and `make test` pass with no warnings.
