Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Speech

if (-not ('AutoClicker.Native.HotKeyForm' -as [type])) {
$referencedAssemblies = @(
    [System.Windows.Forms.Form].Assembly.Location,
    [System.Windows.Forms.Message].Assembly.Location,
    [System.Drawing.Point].Assembly.Location,
    [System.ComponentModel.Component].Assembly.Location
)

Add-Type -ReferencedAssemblies $referencedAssemblies -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

namespace AutoClicker.Native {
public static class MouseClicker {
    [DllImport("user32.dll", CharSet = CharSet.Auto, CallingConvention = CallingConvention.StdCall)]
    public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint cButtons, UIntPtr dwExtraInfo);

    private const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
    private const uint MOUSEEVENTF_LEFTUP = 0x0004;

    public static void LeftClick() {
        mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, UIntPtr.Zero);
        mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, UIntPtr.Zero);
    }
}

public static class NativeHotKey {
    [DllImport("user32.dll")]
    public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll")]
    public static extern bool UnregisterHotKey(IntPtr hWnd, int id);
}

public static class NativeWindow {
    private static readonly IntPtr HWND_BOTTOM = new IntPtr(1);
    private const uint SWP_NOSIZE = 0x0001;
    private const uint SWP_NOMOVE = 0x0002;
    private const uint SWP_NOACTIVATE = 0x0010;

    [DllImport("user32.dll")]
    private static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int x, int y, int cx, int cy, uint flags);

    public static void SendToBackground(IntPtr hWnd) {
        SetWindowPos(hWnd, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    }
}

public class HotKeyForm : System.Windows.Forms.Form {
    public event EventHandler HotKeyPressed;

    protected override void WndProc(ref System.Windows.Forms.Message m) {
        if (m.Msg == 0x0312 && HotKeyPressed != null) {
            HotKeyPressed(this, EventArgs.Empty);
        }

        base.WndProc(ref m);
    }
}
}
"@
}

$form = New-Object AutoClicker.Native.HotKeyForm
$form.Text = "Auto Clicker"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(330, 290)
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$intervalLabel = New-Object System.Windows.Forms.Label
$intervalLabel.Text = "Interval:"
$intervalLabel.Location = New-Object System.Drawing.Point(20, 24)
$intervalLabel.Size = New-Object System.Drawing.Size(120, 24)
$form.Controls.Add($intervalLabel)

$intervalTextBox = New-Object System.Windows.Forms.TextBox
$intervalTextBox.Text = "65"
$intervalTextBox.Location = New-Object System.Drawing.Point(145, 21)
$intervalTextBox.Size = New-Object System.Drawing.Size(70, 24)
$form.Controls.Add($intervalTextBox)

$intervalUnitComboBox = New-Object System.Windows.Forms.ComboBox
$intervalUnitComboBox.DropDownStyle = "DropDownList"
$intervalUnitComboBox.Location = New-Object System.Drawing.Point(220, 21)
$intervalUnitComboBox.Size = New-Object System.Drawing.Size(70, 24)
[void]$intervalUnitComboBox.Items.Add("Seconds")
[void]$intervalUnitComboBox.Items.Add("Milliseconds")
$intervalUnitComboBox.SelectedIndex = 0
$form.Controls.Add($intervalUnitComboBox)

$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = "Start"
$startButton.Location = New-Object System.Drawing.Point(20, 65)
$startButton.Size = New-Object System.Drawing.Size(125, 32)
$form.Controls.Add($startButton)

$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Text = "Stop"
$stopButton.Location = New-Object System.Drawing.Point(165, 65)
$stopButton.Size = New-Object System.Drawing.Size(125, 32)
$stopButton.Enabled = $false
$form.Controls.Add($stopButton)

$soundButton = New-Object System.Windows.Forms.Button
$soundButton.Text = "Sound: On"
$soundButton.Location = New-Object System.Drawing.Point(20, 108)
$soundButton.Size = New-Object System.Drawing.Size(270, 32)
$form.Controls.Add($soundButton)

$voiceLabel = New-Object System.Windows.Forms.Label
$voiceLabel.Text = "Voice:"
$voiceLabel.Location = New-Object System.Drawing.Point(20, 154)
$voiceLabel.Size = New-Object System.Drawing.Size(120, 24)
$form.Controls.Add($voiceLabel)

$voiceComboBox = New-Object System.Windows.Forms.ComboBox
$voiceComboBox.DropDownStyle = "DropDownList"
$voiceComboBox.Location = New-Object System.Drawing.Point(145, 151)
$voiceComboBox.Size = New-Object System.Drawing.Size(145, 24)
$form.Controls.Add($voiceComboBox)

$supportButton = New-Object System.Windows.Forms.Button
$supportButton.Text = "Buy Me A Coffee"
$supportButton.Location = New-Object System.Drawing.Point(165, 210)
$supportButton.Size = New-Object System.Drawing.Size(125, 32)
$supportButton.UseVisualStyleBackColor = $false
$supportButton.BackColor = [System.Drawing.Color]::FromArgb(0, 112, 186)
$supportButton.ForeColor = [System.Drawing.Color]::White
$supportButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$supportButton.FlatAppearance.BorderColor = [System.Drawing.Color]::White
$supportButton.FlatAppearance.BorderSize = 1
$supportButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($supportButton)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Stopped"
$statusLabel.Location = New-Object System.Drawing.Point(20, 184)
$statusLabel.Size = New-Object System.Drawing.Size(270, 24)
$statusLabel.ForeColor = [System.Drawing.Color]::DarkRed
$form.Controls.Add($statusLabel)

$countdownForm = New-Object System.Windows.Forms.Form
$countdownForm.Text = "Auto Clicker Countdown"
$countdownForm.StartPosition = "Manual"
$countdownForm.Size = New-Object System.Drawing.Size(240, 86)
$countdownForm.FormBorderStyle = "FixedToolWindow"
$countdownForm.TopMost = $true
$countdownForm.ShowInTaskbar = $false
$countdownForm.ControlBox = $false

$countdownLabel = New-Object System.Windows.Forms.Label
$countdownLabel.Text = "Auto Clicker: Stopped`r`nPress Alt+1 to Start/Stop"
$countdownLabel.Dock = "Fill"
$countdownLabel.TextAlign = "MiddleCenter"
$countdownLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$countdownForm.Controls.Add($countdownLabel)

$workingArea = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$countdownForm.Location = New-Object System.Drawing.Point(($workingArea.Right - $countdownForm.Width - 12), ($workingArea.Top + 12))

$clickTimer = New-Object System.Windows.Forms.Timer
$countdownTimer = New-Object System.Windows.Forms.Timer
$countdownTimer.Interval = 250
$script:nextClickAt = $null
$script:currentIntervalMilliseconds = 0
$script:currentIntervalDisplay = "65 second(s)"
$script:soundEnabled = $true
$script:lastSpokenSecond = $null
$script:speechSynthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
$script:voiceNameByDisplay = @{}

foreach ($installedVoice in $script:speechSynthesizer.GetInstalledVoices()) {
    if (-not $installedVoice.Enabled) {
        continue
    }

    $voiceInfo = $installedVoice.VoiceInfo
    $displayName = "{0} ({1}, {2})" -f $voiceInfo.Name, $voiceInfo.Gender, $voiceInfo.Age
    $script:voiceNameByDisplay[$displayName] = $voiceInfo.Name
    [void]$voiceComboBox.Items.Add($displayName)

    if ($voiceInfo.Name -eq $script:speechSynthesizer.Voice.Name) {
        $voiceComboBox.SelectedItem = $displayName
    }
}

if ($voiceComboBox.Items.Count -eq 0) {
    [void]$voiceComboBox.Items.Add("Default Windows voice")
    $voiceComboBox.SelectedIndex = 0
    $voiceComboBox.Enabled = $false
} elseif ($voiceComboBox.SelectedIndex -lt 0) {
    $voiceComboBox.SelectedIndex = 0
}

function Invoke-CountdownVoice {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Remaining
    )

    if (-not $script:soundEnabled -or $Remaining -gt 5 -or $Remaining -lt 1 -or $script:lastSpokenSecond -eq $Remaining) {
        return
    }

    $script:lastSpokenSecond = $Remaining
    $spokenNumbers = @("", "one", "two", "three", "four", "five")
    $script:speechSynthesizer.SpeakAsyncCancelAll()
    $script:speechSynthesizer.SpeakAsync($spokenNumbers[$Remaining]) | Out-Null
}

function Move-AutoClickerWindowToBackground {
    if ($form -and $form.IsHandleCreated) {
        [AutoClicker.Native.NativeWindow]::SendToBackground($form.Handle)
    }
}

$intervalTextBox.Add_KeyPress({
    param($sender, $eventArgs)

    if (-not [char]::IsControl($eventArgs.KeyChar) -and -not [char]::IsDigit($eventArgs.KeyChar)) {
        $eventArgs.Handled = $true
    }
})

$clickTimer.Add_Tick({
    [AutoClicker.Native.MouseClicker]::LeftClick()
    $script:nextClickAt = (Get-Date).AddMilliseconds($script:currentIntervalMilliseconds)
    $script:lastSpokenSecond = $null
})

$countdownTimer.Add_Tick({
    if (-not $script:nextClickAt) {
        $countdownLabel.Text = "Auto Clicker: Stopped`r`nPress Alt+1 to Start/Stop"
        $countdownLabel.ForeColor = [System.Drawing.SystemColors]::ControlText
        return
    }

    $remainingMilliseconds = [Math]::Max(0, [Math]::Ceiling(($script:nextClickAt - (Get-Date)).TotalMilliseconds))
    $remainingSeconds = [Math]::Ceiling($remainingMilliseconds / 1000)
    $isCountdownWarningSecond = $remainingSeconds -ge 1 -and $remainingSeconds -le 5 -and $script:currentIntervalMilliseconds -ge 1000
    $remainingText = if ($remainingMilliseconds -ge 1000 -or $isCountdownWarningSecond) { "$remainingSeconds sec" } else { "$remainingMilliseconds ms" }
    $countdownLabel.Text = "Next click in: $remainingText`r`nPress Alt+1 to Start/Stop"

    if ($isCountdownWarningSecond) {
        $countdownLabel.ForeColor = [System.Drawing.Color]::Red
        Invoke-CountdownVoice -Remaining $remainingSeconds
    } else {
        $countdownLabel.ForeColor = [System.Drawing.SystemColors]::ControlText
        $script:lastSpokenSecond = $null
    }
})

function Start-AutoClicker {
    $intervalValue = 0
    if (-not [int]::TryParse($intervalTextBox.Text, [ref]$intervalValue) -or $intervalValue -lt 1) {
        [System.Windows.Forms.MessageBox]::Show("Enter a whole number greater than 0 for the interval.", "Invalid interval", "OK", "Warning") | Out-Null
        return
    }

    $selectedUnit = [string]$intervalUnitComboBox.SelectedItem
    if ([string]::IsNullOrWhiteSpace($selectedUnit)) {
        $selectedUnit = "Seconds"
    }

    if ($selectedUnit -eq "Seconds" -and $intervalValue -gt [Math]::Floor([int]::MaxValue / 1000)) {
        [System.Windows.Forms.MessageBox]::Show("Seconds value is too large for the Windows Forms timer.", "Invalid interval", "OK", "Warning") | Out-Null
        return
    }

    $intervalMilliseconds = if ($selectedUnit -eq "Milliseconds") { $intervalValue } else { $intervalValue * 1000 }
    $intervalDisplay = if ($selectedUnit -eq "Milliseconds") { "$intervalValue millisecond(s)" } else { "$intervalValue second(s)" }

    $script:currentIntervalMilliseconds = $intervalMilliseconds
    $script:currentIntervalDisplay = $intervalDisplay
    [AutoClicker.Native.MouseClicker]::LeftClick()
    $script:nextClickAt = (Get-Date).AddMilliseconds($intervalMilliseconds)
    $script:lastSpokenSecond = $null
    $script:speechSynthesizer.SpeakAsyncCancelAll()
    $clickTimer.Interval = $intervalMilliseconds
    $clickTimer.Start()
    $countdownTimer.Start()
    $startButton.Enabled = $false
    $stopButton.Enabled = $true
    $intervalTextBox.Enabled = $false
    $intervalUnitComboBox.Enabled = $false
    $statusLabel.Text = "Running: clicked once, then every $intervalDisplay"
    $statusLabel.ForeColor = [System.Drawing.Color]::DarkGreen
    $countdownLabel.Text = "Next click in: $intervalDisplay`r`nPress Alt+1 to Start/Stop"
    $countdownLabel.ForeColor = [System.Drawing.SystemColors]::ControlText
}

function Stop-AutoClicker {
    $clickTimer.Stop()
    $countdownTimer.Stop()
    $script:nextClickAt = $null
    $script:lastSpokenSecond = $null
    $script:speechSynthesizer.SpeakAsyncCancelAll()
    $startButton.Enabled = $true
    $stopButton.Enabled = $false
    $intervalTextBox.Enabled = $true
    $intervalUnitComboBox.Enabled = $true
    $statusLabel.Text = "Stopped"
    $statusLabel.ForeColor = [System.Drawing.Color]::DarkRed
    $countdownLabel.Text = "Auto Clicker: Stopped`r`nPress Alt+1 to Start/Stop"
    $countdownLabel.ForeColor = [System.Drawing.SystemColors]::ControlText
    Move-AutoClickerWindowToBackground
}

function Toggle-AutoClicker {
    if ($clickTimer.Enabled) {
        Stop-AutoClicker
    } else {
        Start-AutoClicker
    }
}

$startButton.Add_Click({
    Start-AutoClicker
})

$stopButton.Add_Click({
    Stop-AutoClicker
})

$soundButton.Add_Click({
    $script:soundEnabled = -not $script:soundEnabled
    $soundButton.Text = if ($script:soundEnabled) { "Sound: On" } else { "Sound: Off" }

    if (-not $script:soundEnabled) {
        $script:speechSynthesizer.SpeakAsyncCancelAll()
    }
})

$supportButton.Add_Click({
    Start-Process "https://www.paypal.com/paypalme/peoplecallmerenz"
})

$voiceComboBox.Add_SelectedIndexChanged({
    $selectedVoice = $voiceComboBox.SelectedItem

    if ($selectedVoice -and $script:voiceNameByDisplay.ContainsKey($selectedVoice)) {
        $script:speechSynthesizer.SpeakAsyncCancelAll()
        $script:speechSynthesizer.SelectVoice($script:voiceNameByDisplay[$selectedVoice])
    }
})

$form.Add_Shown({
    $hotKeyId = 1
    $altModifier = 0x0001
    $key1 = 0x31

    if (-not [AutoClicker.Native.NativeHotKey]::RegisterHotKey($form.Handle, $hotKeyId, $altModifier, $key1)) {
        [System.Windows.Forms.MessageBox]::Show("Could not register Alt+1. Another app may already be using it.", "Hotkey unavailable", "OK", "Warning") | Out-Null
    }

    $countdownForm.Show()
})

$form.Add_HotKeyPressed({
    Toggle-AutoClicker
})

$form.Add_FormClosing({
    [AutoClicker.Native.NativeHotKey]::UnregisterHotKey($form.Handle, 1) | Out-Null
    $clickTimer.Stop()
    $countdownTimer.Stop()
    $script:speechSynthesizer.SpeakAsyncCancelAll()
    $script:speechSynthesizer.Dispose()
    $clickTimer.Dispose()
    $countdownTimer.Dispose()
    $countdownForm.Close()
    $countdownForm.Dispose()
})

[void]$form.ShowDialog()