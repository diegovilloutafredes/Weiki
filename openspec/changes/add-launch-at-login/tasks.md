# Tasks

## 1. Login-item model

- [x] 1.1 Write `LoginItem` tests first, with a recording fake service. Cover:
  - off at launch, without registering
  - checked when macOS already has Weiki enabled
  - turning it on registers, and turning it off unregisters
  - requires-approval opens System Settings and stays unchecked
  - a failing call leaves the checkmark matching the fake's status

  Verify that they fail before 1.2.
- [x] 1.2 Implement `LoginItemService`, `SystemLoginItem` (the only file that imports ServiceManagement), and `LoginItem` per design Decisions 1 to 3. Verify that `make test` passes with no warnings.

## 2. Menu item

- [x] 2.1 Add the "Launch at Login" `Toggle` below "Keep Display On", with `WeikiApp` owning the `LoginItem`. Verify in the app through System Events:
  - the item is unchecked at first
  - choosing it adds the ✓, and Weiki shows up among the login items
  - choosing it again removes both, and Weiki keeps running

  Checked by hand. It was left on.
- [x] 2.2 Update the project notes with `LoginItem`, the seam, the source of truth, and the limitation. Verify that the text matches the code and that `openspec validate add-launch-at-login --strict` succeeds.

## 3. Manual

- [ ] 3.1 By hand (needs a person): turn "Launch at Login" on, log out and back in, and check that Weiki starts in the menu bar with no session active. Then switch Weiki off in System Settings > General > Login Items, choose "Launch at Login", and check that System Settings opens at Login Items.
