# Spec Delta

## Purpose

Gives Weiki its only interface: a menu bar icon whose pull-down menu shows the current keep-awake state and offers every control, plus a small window for custom durations. Weiki has no Dock icon and no main window.

## ADDED Requirements

### Requirement: Menu bar presence
The system SHALL show Weiki as a single icon in the menu bar. It SHALL NOT show a Dock icon or an app menu, and it SHALL NOT open any window at launch.

#### Scenario: Launching Weiki
- **WHEN** Weiki launches
- **THEN** a cup icon appears in the menu bar
- **AND** Weiki has no Dock icon and opens no window

### Requirement: Icon reflects the session state
The icon SHALL be an outlined cup while no session is active and a filled cup while a session is active. It SHALL update as soon as the state changes, including when a timed session ends on its own.

#### Scenario: Session starts
- **WHEN** a session starts
- **THEN** the icon becomes a filled cup

#### Scenario: Timed session runs out
- **WHEN** a timed session reaches its end time
- **THEN** the icon becomes an outlined cup without the user opening the menu

### Requirement: Time left in the menu bar
While a session is active, the menu bar SHALL show text next to the cup: "∞" for an indefinite session, or the time left for a timed session. The time left SHALL be rounded up to the next whole minute and written in hours and minutes (for example "42m" or "1h 5m"). It SHALL count down as each minute passes, without the user opening the menu. No text SHALL be shown while no session is active.

#### Scenario: Indefinite session
- **WHEN** an indefinite session is active
- **THEN** the menu bar shows the filled cup followed by "∞"

#### Scenario: Timed session counts down
- **WHEN** a timed session has 41 minutes and 10 seconds left
- **THEN** the menu bar shows the filled cup followed by "42m"
- **AND** it shows "41m" once 41 minutes are left

#### Scenario: More than an hour left
- **WHEN** a timed session has 65 minutes left
- **THEN** the menu bar shows "1h 5m"

#### Scenario: No session
- **WHEN** no session is active
- **THEN** the menu bar shows only the outlined cup

### Requirement: Status line
The first item in the menu SHALL be a status line that cannot be selected. It SHALL describe the state at the moment the menu opens. Times SHALL follow the system's time format, and the abbreviated weekday SHALL be added when the end time is not today. The status line SHALL show the end time, not a countdown.

#### Scenario: No session
- **WHEN** no session is active and the user opens the menu
- **THEN** the status line reads "Weiki is off"

#### Scenario: Indefinite session
- **WHEN** an indefinite session is active and the user opens the menu
- **THEN** the status line reads "Awake indefinitely"

#### Scenario: Session ending today
- **WHEN** the system uses a 24-hour clock and a session ending today at 14:35 is active
- **THEN** the status line reads "Awake until 14:35"

#### Scenario: Session ending on another day
- **WHEN** the system uses a 24-hour clock, today is Thursday, and a session ending on Friday at 09:10 is active
- **THEN** the status line reads "Awake until", followed by the abbreviated weekday and the time (for example "Awake until Fri 09:10")

### Requirement: Turn Off item
The menu SHALL offer a "Turn Off" item only while a session is active, directly below the status line.

#### Scenario: Session active
- **WHEN** a session is active and the user opens the menu
- **THEN** "Turn Off" appears directly below the status line
- **AND** choosing it ends the session

#### Scenario: No session
- **WHEN** no session is active and the user opens the menu
- **THEN** no "Turn Off" item is shown

### Requirement: Duration choices
Under a "Keep Awake For" heading, the menu SHALL offer "Indefinitely", "15 Minutes", "1 Hour", "2 Hours", and "Custom…". Choosing one of the first four SHALL start a session of that length, replace any active session, and close the menu.

#### Scenario: Choosing a preset
- **WHEN** no session is active and the user chooses "1 Hour" at 14:00
- **THEN** a session ending at 15:00 is active
- **AND** the menu closes

#### Scenario: Choosing a preset during a session
- **WHEN** a session is active and the user chooses "15 Minutes"
- **THEN** a session ending 15 minutes from now replaces it

### Requirement: Active option is checked
The option that started the active session SHALL show a checkmark in the menu: the preset the user chose, or "Custom…" for a session started from the Custom duration window. Choosing another option SHALL move the checkmark. Ending the session, by any means, SHALL clear it. Changing "Keep Display On" SHALL NOT change it.

#### Scenario: Choosing an option checks it
- **WHEN** the user chooses "Indefinitely"
- **THEN** "Indefinitely" shows a checkmark the next time the menu opens, and no other duration option does

#### Scenario: Choosing another option moves the checkmark
- **WHEN** "Indefinitely" is checked and the user chooses "1 Hour"
- **THEN** "1 Hour" is checked and "Indefinitely" is not

#### Scenario: Custom session
- **WHEN** the user starts a session from the Custom duration window
- **THEN** "Custom…" is checked

#### Scenario: Session ends
- **WHEN** the checked session is turned off or reaches its end time
- **THEN** no duration option is checked

#### Scenario: Mode change keeps the checkmark
- **WHEN** "1 Hour" is checked and the user changes Keep Display On
- **THEN** "1 Hour" is still checked

### Requirement: Keep Display On item
The menu SHALL show a "Keep Display On" item with a checkmark while the setting is enabled. Choosing the item SHALL toggle the setting.

#### Scenario: Toggling the setting
- **WHEN** Keep Display On is enabled and the user chooses the item
- **THEN** the setting is disabled
- **AND** the item shows no checkmark the next time the menu opens

### Requirement: Custom duration window
Choosing "Custom…" SHALL open a small window in front of other windows. In it, the user sets hours (0 to 24) and minutes (0 to 55, in 5-minute steps), starting at 0 hours and 30 minutes, and starts the session with a Start button.

#### Scenario: Opening the window
- **WHEN** the user chooses "Custom…"
- **THEN** the Custom duration window appears in front of other apps' windows, set to 0 hours and 30 minutes

#### Scenario: Zero duration
- **WHEN** hours and minutes are both 0
- **THEN** the Start button is disabled

#### Scenario: Starting a custom session
- **WHEN** the user sets 1 hour and 30 minutes and clicks Start at 14:00
- **THEN** a session ending at 15:30 is active, replacing any active session
- **AND** the window closes

#### Scenario: Closing without starting
- **WHEN** the user closes the window without clicking Start
- **THEN** the session state is unchanged

### Requirement: Quit item
The menu SHALL end with a "Quit Weiki" item that quits the app.

#### Scenario: Quitting from the menu
- **WHEN** the user chooses "Quit Weiki"
- **THEN** Weiki quits, its menu bar icon disappears, and any active hold is released
