# Spec Delta

## Purpose

Lets people start, stop, and check Weiki sessions from Shortcuts, Siri, and Spotlight, so sessions can run from a keyboard shortcut or a Shortcuts automation instead of a click in the menu.

## ADDED Requirements

### Requirement: Keep Mac Awake action
The Shortcuts app SHALL offer a "Keep Mac Awake" action with an optional duration. Without a duration, the action SHALL start an indefinite session. With a duration from 1 minute to 24 hours, it SHALL start a timed session of that length. The action SHALL replace any active session. The session SHALL follow "Keep Display On" and "Only on AC Power" exactly as a session started from the menu does. If no session is on afterwards, because macOS refused to keep the Mac awake, the action SHALL fail rather than report success. The menu SHALL check "Indefinitely" for an indefinite session, the matching preset for 15 minutes, 1 hour, or 2 hours, and "Custom…" for any other duration.

#### Scenario: Keeping the Mac awake for an hour
- **WHEN** a shortcut runs "Keep Mac Awake" with a duration of 1 hour at 14:00
- **THEN** a session ending at 15:00 is active
- **AND** "1 Hour" is checked in the menu

#### Scenario: No duration
- **WHEN** a shortcut runs "Keep Mac Awake" without a duration
- **THEN** an indefinite session is active and "Indefinitely" is checked

#### Scenario: Another duration
- **WHEN** a shortcut runs "Keep Mac Awake" with a duration of 45 minutes
- **THEN** a session ending 45 minutes later is active and "Custom…" is checked

#### Scenario: macOS refuses to keep the Mac awake
- **WHEN** a shortcut runs "Keep Mac Awake" and the system refuses the hold
- **THEN** the action fails with a message saying Weiki couldn't keep the Mac awake
- **AND** no session is active

#### Scenario: A duration out of range
- **WHEN** a shortcut runs "Keep Mac Awake" with a duration shorter than 1 minute or longer than 24 hours
- **THEN** the action fails with a message asking for a duration from 1 minute to 24 hours
- **AND** the session state is unchanged

### Requirement: Keep Mac Awake Until App Quits action
The Shortcuts app SHALL offer a "Keep Mac Awake Until App Quits" action whose parameter is an app. When the action is set up, the running apps that appear in the Dock SHALL be suggested. When the action runs, it SHALL start a session that lasts until that app quits, as if the app were chosen from the menu's "Until an App Quits" submenu. If the app isn't running when the action runs, the action SHALL fail with a message that names the app, and the session state SHALL be unchanged.

#### Scenario: The app is running
- **WHEN** Keynote is running and a shortcut runs "Keep Mac Awake Until App Quits" with Keynote
- **THEN** the status line reads "Awake until Keynote quits"
- **AND** the session ends when Keynote quits

#### Scenario: The app isn't running
- **WHEN** a shortcut runs "Keep Mac Awake Until App Quits" with Keynote while Keynote isn't running
- **THEN** the action fails with a message saying that Keynote isn't running
- **AND** the session state is unchanged

### Requirement: Turn Off Weiki action
The Shortcuts app SHALL offer a "Turn Off Weiki" action that ends any active session exactly as "Turn Off" in the menu does. It SHALL succeed when no session is active.

#### Scenario: Turning off from a shortcut
- **WHEN** a session is active and a shortcut runs "Turn Off Weiki"
- **THEN** no session is active and no Weiki hold is listed

#### Scenario: Nothing to turn off
- **WHEN** no session is active and a shortcut runs "Turn Off Weiki"
- **THEN** the action succeeds and nothing changes

### Requirement: Is Weiki Keeping the Mac Awake? action
The Shortcuts app SHALL offer an "Is Weiki Keeping the Mac Awake?" action that returns true exactly while Weiki holds the Mac awake. That means false when no session is active and false while a session is paused. The action SHALL also show the status line as its result.

#### Scenario: A session holds the Mac awake
- **WHEN** a session ending at 15:00 holds the Mac awake and a shortcut runs the action
- **THEN** it returns true and shows "Awake until 15:00"

#### Scenario: Paused on battery
- **WHEN** a session is paused on battery and a shortcut runs the action
- **THEN** it returns false

#### Scenario: Off
- **WHEN** no session is active and a shortcut runs the action
- **THEN** it returns false and shows "Weiki is off"

### Requirement: Actions when Weiki isn't running
Running any of the actions SHALL work whether or not Weiki is running. If it isn't running, it SHALL launch in the menu bar, with no window and no Dock icon, and the action SHALL then run.

#### Scenario: Weiki isn't running
- **WHEN** Weiki isn't running and a shortcut runs "Keep Mac Awake" with a duration of 30 minutes
- **THEN** Weiki's cup appears in the menu bar, filled, with "30m"
- **AND** no window opens

### Requirement: Phrases for Siri and Spotlight
Without any setup, Weiki SHALL offer the phrases "Keep my Mac awake with Weiki" (an indefinite session), "Turn off Weiki", and "Is Weiki on?" to Siri and Spotlight.

#### Scenario: Asking Siri
- **WHEN** the user says "Keep my Mac awake with Weiki"
- **THEN** an indefinite session is active

#### Scenario: Weiki's actions in Spotlight
- **WHEN** the user searches Spotlight for "Weiki" on macOS 26 or later, where Spotlight runs app actions
- **THEN** Weiki's actions appear and can be run from there
