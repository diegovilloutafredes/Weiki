# Spec Delta

## Purpose

Keeps the Mac awake until an app the user picks quits, for work whose length isn't known in advance, such as a long build, render, or download.

## ADDED Requirements

### Requirement: Until an App Quits submenu
Under "Keep Awake For", after "Custom…", the menu SHALL offer an "Until an App Quits" submenu. It SHALL list, by name and in alphabetical order, the running apps that appear in the Dock, without Weiki itself. The list SHALL match the running apps whenever the menu opens, including apps launched or quit since it last opened. When no such app is running, the submenu SHALL show one disabled item, "No Apps Running".

#### Scenario: Running apps are listed
- **WHEN** Xcode and Safari are running and the user opens the "Until an App Quits" submenu
- **THEN** it lists "Safari" and then "Xcode"

#### Scenario: An app launched since the menu last opened
- **WHEN** the user launches Preview and then opens the submenu
- **THEN** "Preview" is listed

#### Scenario: Apps without a Dock icon
- **WHEN** an app with no Dock icon, such as a menu bar app, is running
- **THEN** it is not listed

### Requirement: Starting a session until an app quits
Choosing an app in the submenu SHALL start a session with no end time that lasts until that app quits. It SHALL replace any active session and close the menu. The session SHALL follow the running app that was chosen, so it ends when that app quits even if the user opens the app again afterwards.

#### Scenario: Choosing an app
- **WHEN** Xcode is running and the user chooses "Xcode" in the submenu
- **THEN** a session is active with no end time
- **AND** the menu closes

#### Scenario: Replacing a timed session
- **WHEN** a session ending at 15:00 is active and the user chooses "Xcode"
- **THEN** the session lasts until Xcode quits and has no end time

#### Scenario: The app quits before the session starts
- **WHEN** the user chooses an app that has already quit by the time the session would start
- **THEN** no session is active and no Weiki hold is listed

### Requirement: The session ends when the app quits
When the app a session waits for quits, however it quits, including a crash or a force quit, the session SHALL turn itself off and release its hold.

#### Scenario: The app quits
- **WHEN** a session is waiting for Xcode and the user quits Xcode
- **THEN** no session is active and no Weiki hold is listed
- **AND** the icon becomes an outlined cup without the user opening the menu

#### Scenario: The app crashes or is force-quit
- **WHEN** a session is waiting for Xcode and Xcode crashes or is force-quit
- **THEN** no session is active and no Weiki hold is listed

### Requirement: Showing a session until an app quits
While a session waits for an app to quit, the status line SHALL read "Awake until <app> quits". The app's item in the submenu SHALL show a checkmark, and no other duration option SHALL. The hold SHALL carry no system-enforced timeout, and its details SHALL name the app.

#### Scenario: Status line and checkmark
- **WHEN** a session is waiting for Xcode and the user opens the menu
- **THEN** the status line reads "Awake until Xcode quits"
- **AND** "Xcode" shows a checkmark in the "Until an App Quits" submenu

#### Scenario: Hold listed by pmset
- **WHEN** a session is waiting for Xcode with Keep Display On enabled
- **THEN** `pmset -g assertions` lists one Weiki hold with no timeout, whose details say the display is kept on until Xcode quits
