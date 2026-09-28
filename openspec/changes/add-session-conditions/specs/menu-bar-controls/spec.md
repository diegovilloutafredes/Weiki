# Spec Delta

## MODIFIED Requirements

### Requirement: Icon reflects the session state
The icon SHALL be a filled cup while a session holds the Mac awake, and an outlined cup otherwise: while no session is active, and while the active session is paused. It SHALL update as soon as the state changes, including when a timed session ends on its own, when the app a session waits for quits, and when a session pauses or resumes.

#### Scenario: Session starts
- **WHEN** a session starts and holds the Mac awake
- **THEN** the icon becomes a filled cup

#### Scenario: Timed session runs out
- **WHEN** a timed session reaches its end time
- **THEN** the icon becomes an outlined cup without the user opening the menu

#### Scenario: Session pauses on battery
- **WHEN** "Only on AC Power" is on, a session is active, and the user unplugs the Mac
- **THEN** the icon becomes an outlined cup without the user opening the menu

### Requirement: Time left in the menu bar
While a session is active, the menu bar SHALL show text next to the cup: "∞" for an indefinite session, the time left for a timed session, or the app's name for a session that waits for an app to quit. The time left SHALL be rounded up to the next whole minute and written in hours and minutes (for example "42m" or "1h 5m"). It SHALL count down as each minute passes, without the user opening the menu. An app's name longer than 10 characters SHALL be cut to its first 10 characters, without a trailing space, followed by "…". No text SHALL be shown while no session is active.

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

#### Scenario: Waiting for an app
- **WHEN** a session is waiting for Xcode
- **THEN** the menu bar shows the filled cup followed by "Xcode"

#### Scenario: A long app name
- **WHEN** a session is waiting for an app named "Visual Studio Code"
- **THEN** the menu bar shows the filled cup followed by "Visual Stu…"

#### Scenario: A long app name cut at a space
- **WHEN** a session is waiting for an app named "Microsoft Word"
- **THEN** the menu bar shows the filled cup followed by "Microsoft…"

#### Scenario: No session
- **WHEN** no session is active
- **THEN** the menu bar shows only the outlined cup

### Requirement: Duration choices
Under a "Keep Awake For" heading, the menu SHALL offer "Indefinitely", "15 Minutes", "1 Hour", "2 Hours", "Custom…", and the "Until an App Quits" submenu. Choosing one of the first four SHALL start a session of that length, replace any active session, and close the menu.

#### Scenario: Choosing a preset
- **WHEN** no session is active and the user chooses "1 Hour" at 14:00
- **THEN** a session ending at 15:00 is active
- **AND** the menu closes

#### Scenario: Choosing a preset during a session
- **WHEN** a session is active and the user chooses "15 Minutes"
- **THEN** a session ending 15 minutes from now replaces it
