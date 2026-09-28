# Spec Delta

## Purpose

Shows which other processes are keeping the Mac awake, so the user can see why it isn't sleeping without opening Terminal.

## ADDED Requirements

### Requirement: Also Keeping the Mac Awake section
While other processes keep the Mac from idle-sleeping, the menu SHALL show a section titled "Also Keeping the Mac Awake" after the status line and "Turn Off", and before "Keep Awake For". It SHALL list one item per name, sorted by name, so several processes with the same name, such as two `caffeinate` runs, share one item. Each item SHALL give the process's name and say "keeps the display on" when the process keeps the display awake, or "keeps the Mac awake" when it keeps only the system awake. An app SHALL be named as the Dock names it, and any other process by its process name. The items SHALL only inform, and choosing one SHALL do nothing. When no other process keeps the Mac awake, the section SHALL NOT appear.

#### Scenario: A process keeps the Mac awake
- **WHEN** `caffeinate -i` is running and the user opens the menu
- **THEN** the section lists "caffeinate — keeps the Mac awake"

#### Scenario: A process keeps the display on
- **WHEN** `caffeinate -d` is running and the user opens the menu
- **THEN** the section lists "caffeinate — keeps the display on"

#### Scenario: Several processes
- **WHEN** Zoom keeps the display on and `caffeinate -i` is running
- **THEN** the section lists "caffeinate — keeps the Mac awake" and then "zoom.us — keeps the display on", sorted by name

#### Scenario: Two processes with the same name
- **WHEN** two `caffeinate -i` runs are active
- **THEN** the section lists "caffeinate — keeps the Mac awake" once

#### Scenario: Nothing else keeps the Mac awake
- **WHEN** no process other than macOS's own power management keeps the Mac awake
- **THEN** the menu shows no "Also Keeping the Mac Awake" section

### Requirement: What counts as keeping the Mac awake
A process SHALL be listed when it holds an assertion that prevents idle display sleep or idle system sleep, or keeps the system awake for network clients. A process holding both kinds SHALL be listed once, as keeping the display on. These SHALL NOT be listed:
- Weiki's own hold
- the assertion macOS's power manager holds while the display is on
- assertion types internal to macOS
- the "user is active" signal
- assertions that don't keep the Mac awake, such as background tasks

#### Scenario: Weiki's own session
- **WHEN** a Weiki session is active and no other process keeps the Mac awake
- **THEN** the menu shows no "Also Keeping the Mac Awake" section

#### Scenario: The display is on and the user is active
- **WHEN** the only assertions are the power manager's own and the "user is active" signal
- **THEN** the menu shows no "Also Keeping the Mac Awake" section

### Requirement: Current when the menu opens
The list SHALL reflect the processes keeping the Mac awake at the moment the menu opens, including ones that started or stopped since it last opened.

#### Scenario: A process starts after the menu last opened
- **WHEN** the user opens and closes the menu, then runs `caffeinate -i`, then opens the menu again
- **THEN** the section lists "caffeinate — keeps the Mac awake"

#### Scenario: A process stops
- **WHEN** `caffeinate -i` exits and the user then opens the menu
- **THEN** it is no longer listed
