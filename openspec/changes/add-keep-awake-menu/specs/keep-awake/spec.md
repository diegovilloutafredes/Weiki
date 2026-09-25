# Spec Delta

## Purpose

Keeps the Mac from idle-sleeping on the user's behalf, either indefinitely or for a chosen duration, in a display-on or system-only mode. It guarantees that every hold ends when it should: when the user turns it off, when its time runs out, or when Weiki quits.

## ADDED Requirements

### Requirement: Indefinite session
The system SHALL let the user start a session that keeps the Mac awake with no end time. The session SHALL last until the user turns it off or quits Weiki.

#### Scenario: Starting an indefinite session
- **WHEN** no session is active and the user starts an indefinite session
- **THEN** the Mac is prevented from idle sleep
- **AND** the session has no end time

### Requirement: Timed session
The system SHALL let the user start a session with a duration. The session's end time SHALL be the moment it starts plus that duration.

#### Scenario: Starting a one-hour session
- **WHEN** no session is active and the user starts a 1-hour session at 14:00
- **THEN** the Mac is prevented from idle sleep
- **AND** the session's end time is 15:00

### Requirement: Starting a session while one is active replaces it
Starting a session while another is active SHALL replace it. The new duration SHALL count from the moment it is chosen, and the Mac SHALL stay held awake throughout the switch.

#### Scenario: Switching from indefinite to 15 minutes
- **WHEN** an indefinite session is active and the user starts a 15-minute session at 10:00
- **THEN** the session's end time is 10:15
- **AND** `pmset -g assertions` lists exactly one Weiki hold

#### Scenario: Restarting a timed session
- **WHEN** a session ending at 11:00 is active and the user starts a 1-hour session at 10:30
- **THEN** the session's end time is 11:30

### Requirement: Turning a session off
Turning a session off SHALL release its hold immediately.

#### Scenario: User turns off an active session
- **WHEN** a session is active and the user turns it off
- **THEN** `pmset -g assertions` lists no Weiki hold
- **AND** the Mac follows its normal sleep settings again

### Requirement: Timed sessions end on their own
A timed session SHALL turn itself off and release its hold when its end time is reached. This SHALL also happen when the Mac was asleep at the end time.

#### Scenario: End time reached while awake
- **WHEN** a timed session reaches its end time
- **THEN** no session is active and no Weiki hold is listed

#### Scenario: End time passed while the Mac was asleep
- **WHEN** the Mac is put to sleep (for example by closing the lid) during a timed session and wakes after the session's end time
- **THEN** within one minute of waking no session is active and no Weiki hold is listed

### Requirement: System-enforced end time
Every timed hold SHALL carry its remaining time as a system-enforced timeout that releases the hold. This way the hold still ends on time if Weiki stops responding. An indefinite hold SHALL carry no timeout.

#### Scenario: Timeout visible to the system
- **WHEN** a timed session with 90 minutes remaining is active
- **THEN** `pmset -g assertions` shows the Weiki hold with a timeout of about 5400 seconds and a release action when the timeout fires

#### Scenario: Indefinite hold has no timeout
- **WHEN** an indefinite session is active
- **THEN** the Weiki hold shows no timeout

### Requirement: Display mode
While a session is active, the system SHALL keep the display awake when "Keep Display On" is enabled. When the setting is disabled, the system SHALL keep only the system awake and let the display turn off after its normal idle time.

#### Scenario: Keep Display On enabled
- **WHEN** a session is active with Keep Display On enabled
- **THEN** neither the display nor the system goes to idle sleep
- **AND** the Weiki hold has type `PreventUserIdleDisplaySleep`

#### Scenario: Keep Display On disabled
- **WHEN** a session is active with Keep Display On disabled
- **THEN** the system does not idle-sleep, and the display turns off after its normal idle time
- **AND** the Weiki hold has type `PreventUserIdleSystemSleep`

### Requirement: Display mode default and persistence
"Keep Display On" SHALL be enabled on first launch. The user's choice SHALL persist across relaunches.

#### Scenario: First launch
- **WHEN** Weiki launches for the first time
- **THEN** Keep Display On is enabled

#### Scenario: Choice survives a relaunch
- **WHEN** the user disables Keep Display On, quits, and relaunches Weiki
- **THEN** Keep Display On is still disabled

### Requirement: Changing the display mode during a session
Changing "Keep Display On" while a session is active SHALL apply the new mode immediately without changing the session's end time. The Mac SHALL stay held awake throughout the change.

#### Scenario: Disabling Keep Display On mid-session
- **WHEN** a session ending at 16:00 is active with Keep Display On enabled, and the user disables it
- **THEN** exactly one Weiki hold is listed, with type `PreventUserIdleSystemSleep`
- **AND** the session's end time is still 16:00

#### Scenario: Changing the mode while no session is active
- **WHEN** no session is active and the user changes Keep Display On
- **THEN** no hold is created
- **AND** the next session uses the new choice

### Requirement: Quitting and launching
Quitting Weiki SHALL release any active hold. Launching Weiki SHALL always start with no active session.

#### Scenario: Quit during a session
- **WHEN** a session is active and the user quits Weiki
- **THEN** `pmset -g assertions` lists no Weiki hold

#### Scenario: Launch never resumes a session
- **WHEN** Weiki launches, even if a session was active when it last quit
- **THEN** no session is active

### Requirement: Identifiable to system tools
Every hold SHALL be identified to the system by the name "Weiki", with details that describe the mode and when the session ends.

#### Scenario: Hold listed by pmset
- **WHEN** a 1-hour session ending at 15:00 is active with Keep Display On enabled
- **THEN** `pmset -g assertions` lists a hold named "Weiki", owned by the Weiki process, whose details say the display is kept on and give the 15:00 end time

#### Scenario: Activity Monitor
- **WHEN** a session is active
- **THEN** Activity Monitor shows Weiki as preventing sleep

### Requirement: Refused hold
If the system refuses to create a hold, no session SHALL be active afterwards. Weiki SHALL never present the Mac as held awake when it is not.

#### Scenario: Hold refused when starting
- **WHEN** the user starts a session and the system refuses the hold
- **THEN** no session is active and no Weiki hold is listed

#### Scenario: Hold refused when replacing
- **WHEN** a session is active and the system refuses the hold for its replacement (a new duration or a mode change)
- **THEN** the previous hold is released and no session is active
