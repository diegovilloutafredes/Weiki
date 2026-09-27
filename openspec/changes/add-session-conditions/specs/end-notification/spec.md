# Spec Delta

## Purpose

Tells the user when a timed session has run out, so they know the Mac can sleep again, without Weiki ever showing a notification the user didn't ask for.

## ADDED Requirements

### Requirement: Notify When Time's Up item
The menu SHALL show a "Notify When Time's Up" item below "Only on AC Power". The item SHALL show a checkmark only while the setting is on and macOS allows Weiki's notifications, as read at launch and after each choice. The setting SHALL be off on first launch, and the user's choice SHALL persist across relaunches.

#### Scenario: First launch
- **WHEN** Weiki launches for the first time
- **THEN** "Notify When Time's Up" shows no checkmark
- **AND** macOS has not asked the user about Weiki's notifications

### Requirement: Asking for permission
Choosing "Notify When Time's Up" while it is unchecked SHALL turn the setting on. If macOS hasn't asked the user about Weiki's notifications yet, it SHALL ask then. If the user has declined them, or switched them off in System Settings, choosing the item SHALL instead open System Settings at Weiki's notification settings, and the item SHALL stay unchecked. Choosing the item while it is checked SHALL turn the setting off.

#### Scenario: Turning it on for the first time
- **WHEN** "Notify When Time's Up" is unchecked, macOS hasn't asked about Weiki's notifications yet, and the user chooses it
- **THEN** macOS asks whether Weiki may send notifications
- **AND** the item shows a checkmark if the user allows them, and stays unchecked if the user doesn't

#### Scenario: Notifications declined earlier
- **WHEN** the user declined Weiki's notifications earlier and chooses "Notify When Time's Up"
- **THEN** System Settings opens at Weiki's notification settings
- **AND** the item stays unchecked

#### Scenario: Turning it off
- **WHEN** "Notify When Time's Up" is checked and the user chooses it
- **THEN** the item shows no checkmark, and timed sessions that run out post nothing

### Requirement: Notification when a timed session runs out
While the setting is on, the system SHALL post one notification when a timed session reaches its end time. This includes a session whose end passed while the Mac was asleep or while the session was paused. The notification SHALL say that Weiki is off and when the session ended. No notification SHALL be posted when a session ends any other way: the user turns it off or replaces it, the app it waits for quits, the hold is refused, or Weiki quits.

#### Scenario: A timed session runs out
- **WHEN** the setting is on and a session ending at 15:00 reaches its end time
- **THEN** one notification appears, saying that Weiki is off and that the session ended at 15:00

#### Scenario: The end passed while the Mac was asleep
- **WHEN** the setting is on and the Mac wakes after a timed session's end time
- **THEN** one notification appears within a minute of waking

#### Scenario: The user turns the session off
- **WHEN** the setting is on and the user chooses "Turn Off" during a timed session
- **THEN** no notification appears

#### Scenario: The setting is off
- **WHEN** the setting is off and a timed session reaches its end time
- **THEN** no notification appears
