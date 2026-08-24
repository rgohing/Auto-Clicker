# Auto Clicker PowerShell GUI

This folder contains `AutoClicker.ps1`, a Windows PowerShell GUI tool that simulates a left mouse click at a fixed interval. The user can select whether the interval is measured in seconds or milliseconds, then start or stop clicking from the GUI or by pressing `Alt+1`. The default click interval is 65 seconds.

## Prerequisites

1. Use Windows. The script uses Windows Forms and `user32.dll`, so it is intended for Windows only.
2. Use PowerShell 5.1 or PowerShell 7+.
3. Allow local PowerShell scripts to run. If blocked by execution policy, run PowerShell as the current user and use:

   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
   ```

4. Run the script in an interactive desktop session. It needs access to the mouse pointer and visible Windows desktop.
5. Make sure `Alt+1` is not already registered by another application. If another app owns it, the script shows a warning and the GUI buttons still work.

## How to Run

1. Open this folder.
2. Double-click `AutoClicker.exe` to start the GUI.
3. If you want to run the PowerShell script version instead, open PowerShell and go to the folder where this README and `AutoClicker.ps1` are saved.
4. Run the script from the current folder:

   ```powershell
   & .\AutoClicker.ps1
   ```

5. Alternatively, run it from any location by using the script path relative to this README:

   ```powershell
   $scriptPath = Join-Path $PSScriptRoot "AutoClicker.ps1"
   & $scriptPath
   ```

6. The `Auto Clicker` window opens in the center of the screen.
7. A small countdown window appears in the upper-right portion of the screen and shows the `Press Alt+1 to Start/Stop` shortcut hint.

## User Guide

1. Enter the click interval in the `Interval` input box. The default value is `65`.
2. Select the interval unit from the dropdown:

   - `Seconds`
   - `Milliseconds`

3. Only whole numbers are accepted. Example values:

   ```text
   1
   5
   65
   500
   30
   ```

4. Move the mouse pointer to the location where you want the first left click.
5. Click `Start` to perform one left click immediately and begin automatic clicking.
6. Move the mouse pointer as needed for repeated left clicks.
7. After the immediate click, the script starts the countdown and clicks at the current mouse pointer location every selected interval.
8. Use the `Sound: On` / `Sound: Off` button to mute or unmute the spoken countdown warning.
9. Use the `Voice` dropdown to choose from the Windows speech voices installed on the computer.
10. Click the PayPal-styled `Support Me` button to open the support page in your default browser:

   ```text
   https://www.paypal.com/paypalme/peoplecallmerenz
   ```

11. Click `Stop` to stop automatic clicking. After stopping, the main `Auto Clicker` window is sent behind other windows.
12. Press `Alt+1` at any time to toggle between Start and Stop.
13. Close the main `Auto Clicker` window to exit the script.

## Countdown Window

The countdown window is always visible on top of other windows and is positioned near the upper-right part of the primary screen.

When stopped, it shows:

```text
Auto Clicker: Stopped
Press Alt+1 to Start/Stop
```

When running, it shows the remaining time before the next click:

```text
Next click in: 65 sec
Press Alt+1 to Start/Stop
```

For millisecond intervals below one second, it shows milliseconds instead:

```text
Next click in: 500 ms
Press Alt+1 to Start/Stop
```

The countdown refreshes every 250 milliseconds. Values of one second or higher are displayed as rounded-up whole seconds. Values below one second are displayed in milliseconds. When the countdown reaches 5 seconds or lower, the countdown text turns red. If sound is enabled and at least one second remains, the script speaks each displayed warning number once: `five`, `four`, `three`, `two`, and `one`.

The available voice options come from Windows text-to-speech voices installed on the machine. The dropdown shows the voice name plus the gender and age metadata reported by Windows, such as `Female` or `Adult`. Voice types like child or baby voices only appear if that kind of voice is installed in Windows.

## Step-by-Step: How the Script Works

1. The script loads the required Windows GUI assemblies:

   ```powershell
   Add-Type -AssemblyName System.Windows.Forms
   Add-Type -AssemblyName System.Drawing
   ```

2. It compiles small embedded C# helper classes using `Add-Type`.

3. `MouseClicker` calls the Windows `user32.dll` `mouse_event` function to simulate a left mouse button down and left mouse button up action.

4. `NativeHotKey` calls Windows API functions to register and unregister the global hotkey.

5. `HotKeyForm` extends a normal Windows Form and listens for the Windows hotkey message `0x0312`.

6. The main form is created with:

   - `Interval` label
   - Numeric interval textbox
   - Interval unit dropdown for `Seconds` or `Milliseconds`
   - `Start` button
   - `Stop` button
   - `Sound: On` / `Sound: Off` toggle button
   - `Voice` dropdown for installed Windows speech voices
   - PayPal-styled `Support Me` button
   - Status label

7. A second small form is created for the countdown display and the `Press Alt+1 to Start/Stop` shortcut hint.

8. The countdown form is set to `TopMost`, so it remains visible above normal windows.

9. The countdown form is positioned using the primary screen working area:

   ```powershell
   $workingArea = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
   ```

10. The interval textbox blocks non-numeric input by handling the `KeyPress` event.

11. The script uses two timers:

    - `$clickTimer` performs the actual left click.
    - `$countdownTimer` refreshes the countdown display.

12. When `Start-AutoClicker` runs, it validates the interval value and selected unit, converts the active interval to milliseconds, performs one left click immediately, starts both timers, disables the interval controls, and updates the status labels.

13. After the immediate click, the countdown starts and points to the next scheduled click.

14. When `$clickTimer` ticks, the script sends another left click and calculates the next click time.

15. When `$countdownTimer` ticks, the script calculates how much time remains before the next click and updates the countdown window in seconds or milliseconds.

16. When the countdown reaches 5 seconds or lower, the countdown label turns red. If sound is enabled and at least one second remains, the script speaks the current number.

17. When `Stop-AutoClicker` runs, it stops both timers, re-enables the interval controls, cancels any active speech, changes both labels back to stopped, and sends the main window behind other windows.

18. `Toggle-AutoClicker` checks whether the click timer is running:

    - If running, it stops the auto clicker.
    - If stopped, it starts the auto clicker.

19. The `Start` button calls `Start-AutoClicker`.

20. The `Stop` button calls `Stop-AutoClicker`.

21. The sound toggle button switches the spoken countdown warning on or off.

22. The support button uses a PayPal-style blue background with white bold text and a yellow border accent, then opens `https://www.paypal.com/paypalme/peoplecallmerenz` in the default browser when clicked.

23. The voice dropdown switches the speech synthesizer to another installed Windows voice.

24. When the main form is shown, the script registers `Alt+1` as the global toggle hotkey.

25. When the main form closes, the script unregisters the hotkey, stops the timers, cancels and disposes the speech synthesizer, disposes timer objects, and closes the countdown window.

## Notes

- The auto clicker clicks once immediately when started, then clicks wherever the mouse pointer is located when the timer fires.
- It does not lock the click position.
- Spoken countdown uses the Windows speech synthesizer through `System.Speech` and can only use installed Windows voices.
- Millisecond intervals are supported, but very small values may be limited by Windows Forms timer accuracy, system load, and desktop responsiveness.
- The countdown window cannot be closed separately; close the main Auto Clicker window to exit everything.
- Stopping the clicker sends the main `Auto Clicker` window to the background, so it does not stay in front after the automation stops.
- If `Alt+1` cannot be registered, use the `Start` and `Stop` buttons instead.
- The PayPal-styled `Support Me` button opens the PayPal support page with the default Windows browser.
