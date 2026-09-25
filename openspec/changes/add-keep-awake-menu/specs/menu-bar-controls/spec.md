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
Choosing "Custom…" SHALL open a small window in front of other windows, just below the menu bar. The first time it opens after Weiki launches, it SHALL be centered horizontally on the point where "Custom…" was chosen, which is under the Weiki icon, and kept fully on screen. When the pointer isn't near the menu bar (the menu was used from the keyboard), it SHALL appear at the top-right of the screen instead. After that, it SHALL reopen where it was last, including wherever the user moved it.

In the window, the user types a duration into one text field, which SHALL open containing "30m". The field SHALL accept minutes as a bare number ("90") or with "m" ("45m"), hours with "h" ("2h"), hours and minutes ("1h30", "1h 30m"), and "h:mm" ("1:30"), from 1 minute up to 24 hours. Below the field, the window SHALL show when a session would end ("Until 15:42", with the weekday when it isn't today), or a hint when the text isn't a valid duration. Start, or the Return key, SHALL start a session of that duration and close the window. Start SHALL be disabled while the text isn't a valid duration. The Escape key SHALL close the window without changes.

#### Scenario: Opening the window
- **WHEN** the user clicks "Custom…" for the first time since Weiki launched
- **THEN** the Custom duration window appears in front of other apps' windows, just below the menu bar and under the Weiki icon, with "30m" entered

#### Scenario: Icon near the edge of the screen
- **WHEN** the Weiki icon is close to the right edge of the screen and the user clicks "Custom…" for the first time since Weiki launched
- **THEN** the window appears just below the menu bar, entirely on screen

#### Scenario: Chosen from the keyboard
- **WHEN** the user chooses "Custom…" from the keyboard for the first time since Weiki launched, with the pointer away from the menu bar
- **THEN** the window appears at the top-right of the screen, just below the menu bar

#### Scenario: Reopening where it was
- **WHEN** the user moves the window, closes it, and chooses "Custom…" again
- **THEN** the window reopens where the user left it

#### Scenario: Typing a duration
- **WHEN** the user types "1h30" at 14:00
- **THEN** the window shows "Until 15:30" and Start is enabled

#### Scenario: A bare number is minutes
- **WHEN** the user types "90" and clicks Start at 14:00
- **THEN** a session ending at 15:30 is active, replacing any active session
- **AND** the window closes

#### Scenario: One-minute session
- **WHEN** the user types "1" and clicks Start at 14:00
- **THEN** a session ending at 14:01 is active, and the menu bar shows "1m"

#### Scenario: Text that isn't a duration
- **WHEN** the user types "abc", "0", or "25h"
- **THEN** the window shows a hint instead of an end time
- **AND** Start is disabled

#### Scenario: Closing without starting
- **WHEN** the user closes the window, or presses Escape, without starting a session
- **THEN** the session state is unchanged

### Requirement: Quit item
The menu SHALL end with a "Quit Weiki" item that quits the app.

#### Scenario: Quitting from the menu
- **WHEN** the user chooses "Quit Weiki"
- **THEN** Weiki quits, its menu bar icon disappears, and any active hold is released
