# Proposal

## Why

"Weiki is off" doesn't mean the Mac will sleep. Another app may be keeping it awake: a video call, a build, a download, audio playing, or a `caffeinate` someone forgot. Today finding out takes `pmset -g assertions` in Terminal. This is the last layer of the roadmap: show it in the menu.

## What Changes

- A section in the menu, "Also Keeping the Mac Awake", that appears while other processes keep the Mac from idle-sleeping. It lists one item per process name, sorted by name, each saying whether it keeps the display on or only the Mac awake, for example "Zoom — keeps the display on" or "caffeinate — keeps the Mac awake". The items only inform; choosing one does nothing.
- The list is current when the menu opens.
- The system's own bookkeeping is left out, because it's always there:
  - the power manager keeping the Mac awake while the display is on
  - assertions internal to macOS
  - the "user is active" signal

  Weiki's own hold is left out too.

## Capabilities

### New Capabilities

- `other-sleep-blockers`: which other processes the menu lists as keeping the Mac awake, how each reads, and when the list is current.

### Modified Capabilities

None. The section is new, and the existing menu items keep their order.

## Impact

- **Code:** reading all processes' assertions (`IOPMCopyAssertionsByProcess`, in the file that already owns power assertions), a small model, and the menu section. No new dependency or permission: any process may read the system's assertions.
- **Order:** it builds on the menu from `add-keep-awake-menu` and adds only new requirements, so it can be archived on its own.
