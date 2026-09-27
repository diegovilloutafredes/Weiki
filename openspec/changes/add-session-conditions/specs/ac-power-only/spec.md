# Spec Delta

## Purpose

Lets the user keep the Mac awake only while it is plugged in, so a forgotten session never drains the battery. On battery a session pauses, and it resumes when the Mac is plugged in again.

## ADDED Requirements

### Requirement: Only on AC Power item
The menu SHALL show an "Only on AC Power" item below "Keep Display On", with a checkmark while the setting is on. Choosing the item SHALL toggle the setting. The setting SHALL be off on first launch, and the user's choice SHALL persist across relaunches.

#### Scenario: First launch
- **WHEN** Weiki launches for the first time
- **THEN** "Only on AC Power" shows no checkmark

#### Scenario: Choice survives a relaunch
- **WHEN** the user turns on "Only on AC Power", quits, and relaunches Weiki
- **THEN** "Only on AC Power" still shows a checkmark

### Requirement: Paused on battery
While "Only on AC Power" is on and the Mac runs on battery power (its own battery, or a UPS's), the active session SHALL be paused, and Weiki SHALL hold nothing. This SHALL take precedence over every other requirement that keeps the Mac awake; those apply again when the session resumes. A paused session SHALL keep its end time, the app it waits for, its checkmark, and the "Turn Off" item, and a timed session SHALL still end at its end time. A session started, or a setting turned on, while the Mac runs on battery SHALL pause immediately.

#### Scenario: Unplugging during a session
- **WHEN** "Only on AC Power" is on, a session ending at 15:00 is active, and the user unplugs the Mac at 14:00
- **THEN** `pmset -g assertions` lists no Weiki hold
- **AND** the session's end time is still 15:00

#### Scenario: Starting a session on battery
- **WHEN** "Only on AC Power" is on, the Mac runs on battery, and the user chooses "1 Hour"
- **THEN** a paused session ending in one hour is active, and no Weiki hold is listed

#### Scenario: Turning the setting on while on battery
- **WHEN** a session is active, the Mac runs on battery, and the user turns on "Only on AC Power"
- **THEN** the session is paused and no Weiki hold is listed

#### Scenario: A paused session reaches its end time
- **WHEN** a paused timed session reaches its end time
- **THEN** no session is active

#### Scenario: On AC power
- **WHEN** "Only on AC Power" is on and the Mac runs on AC power
- **THEN** sessions hold the Mac awake as usual

### Requirement: Resuming on AC power
When the Mac is plugged in again, or "Only on AC Power" is turned off, a paused session SHALL resume. Weiki SHALL hold the Mac awake again in the current display mode, with the session's end time unchanged. If the system refuses the hold, no session SHALL be active afterwards.

#### Scenario: Plugging in again
- **WHEN** a session ending at 15:00 is paused and the user plugs the Mac in at 14:30
- **THEN** `pmset -g assertions` lists one Weiki hold with a timeout of about 1800 seconds
- **AND** the session's end time is still 15:00

#### Scenario: Turning the setting off while paused
- **WHEN** a session is paused and the user turns off "Only on AC Power"
- **THEN** the session resumes and one Weiki hold is listed

#### Scenario: Display mode changed while paused
- **WHEN** a session is paused, the user disables Keep Display On, and then plugs the Mac in
- **THEN** the Weiki hold has type `PreventUserIdleSystemSleep`

#### Scenario: Hold refused when resuming
- **WHEN** a paused session resumes and the system refuses the hold
- **THEN** no session is active and no Weiki hold is listed

### Requirement: Showing a paused session
While a session is paused, the status line SHALL begin with "Paused on battery". For a timed session it SHALL continue with the end time, and for a session that waits for an app, with the app ("Paused on battery, until 14:35", "Paused on battery, until Xcode quits"). An indefinite session SHALL read just "Paused on battery". The menu bar SHALL show the session's usual text, with the cup outlined.

#### Scenario: Paused timed session
- **WHEN** the system uses a 24-hour clock, a session ending today at 14:35 is paused, and the user opens the menu
- **THEN** the status line reads "Paused on battery, until 14:35"
- **AND** the menu bar shows the outlined cup followed by the time left

#### Scenario: Paused indefinite session
- **WHEN** an indefinite session is paused and the user opens the menu
- **THEN** the status line reads "Paused on battery"
- **AND** the menu bar shows the outlined cup followed by "∞"
