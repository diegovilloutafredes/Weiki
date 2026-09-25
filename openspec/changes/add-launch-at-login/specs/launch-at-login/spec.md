# Spec Delta

## Purpose

Lets the user choose whether Weiki starts automatically at login, with the menu always showing what macOS actually has registered.

## ADDED Requirements

### Requirement: Launch at Login item
The menu SHALL include a "Launch at Login" item below "Keep Display On". The item SHALL show a checkmark exactly when macOS reports Weiki as an enabled login item.

#### Scenario: Not registered
- **WHEN** Weiki is not a login item and the user opens the menu
- **THEN** "Launch at Login" shows no checkmark

#### Scenario: Already registered
- **WHEN** Weiki launches and macOS already has it as an enabled login item
- **THEN** "Launch at Login" shows a checkmark

### Requirement: Off by default
Weiki SHALL NOT register itself as a login item unless the user chooses "Launch at Login".

#### Scenario: First launch
- **WHEN** Weiki launches for the first time
- **THEN** it is not added as a login item
- **AND** "Launch at Login" shows no checkmark

### Requirement: Turning launch at login on and off
Choosing "Launch at Login" SHALL register Weiki as a login item when the item is unchecked, and unregister it when the item is checked. Afterwards the checkmark SHALL reflect what macOS reports.

#### Scenario: Turning it on
- **WHEN** "Launch at Login" is unchecked and the user chooses it
- **THEN** Weiki is registered as a login item and appears in System Settings > General > Login Items
- **AND** the item shows a checkmark

#### Scenario: Turning it off
- **WHEN** "Launch at Login" is checked and the user chooses it
- **THEN** Weiki is no longer a login item, and the item shows no checkmark
- **AND** Weiki keeps running

#### Scenario: Starting at login
- **WHEN** "Launch at Login" is checked and the user logs out and back in
- **THEN** Weiki starts in the menu bar with no session active

#### Scenario: Registration fails
- **WHEN** macOS refuses to register or unregister Weiki
- **THEN** the checkmark still matches what macOS reports

### Requirement: Approval needed
When macOS reports that Weiki's login item needs the user's approval, because it was switched off in System Settings, choosing "Launch at Login" SHALL open System Settings at the Login Items page. The item SHALL stay unchecked until the user allows it.

#### Scenario: Switched off in System Settings
- **WHEN** the user has switched Weiki off in System Settings > General > Login Items and then chooses "Launch at Login"
- **THEN** System Settings opens at Login Items
- **AND** "Launch at Login" shows no checkmark
