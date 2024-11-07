# Load Windows Forms and Drawing Assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to Check Admin Privileges
function Check-Admin {
    $adminCheck = [System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    return $adminCheck.IsInRole($adminRole)
}

# Function to Restart Script as Admin
function Restart-AsAdmin {
    if (-not (Check-Admin)) {
        [System.Windows.Forms.MessageBox]::Show(
            "The script needs to be run as Administrator for full functionality.",
            "Administrator Privileges Required",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -Wait
        Exit
    }
}

# Function to Update Progress Bar
function Update-ProgressBar {
    param (
        [int]$step
    )
    if ($progressBar.Value + $step -le $progressBar.Maximum) {
        $progressBar.Value += $step
        $form.Refresh()
    }
}

# Function to Clear Memory
function Clear-Memory {
    param ([ref]$statusLabel)
    $statusLabel.Value.Text = "Preparing to clear memory..."
    Update-ProgressBar -step 20

    # Simulate clearing memory with sleep
    Start-Sleep -Seconds 1
    Update-ProgressBar -step 30
    
    $statusLabel.Value.Text = "Clearing memory..."
    Start-Sleep -Seconds 1
    Update-ProgressBar -step 30
    
	$tempDir = "$env:TEMP\RAMMap"
    $ramMapPath = "$tempDir\RAMMap64.exe"

    # Download and extract RAMMap if it doesn't exist
    if (-not (Test-Path $ramMapPath)) {
        if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir | Out-Null }
        $url = "https://download.sysinternals.com/files/RAMMap.zip"
        $zipPath = "$tempDir\RAMMap.zip"
        try {
            Invoke-WebRequest -Uri $url -OutFile $zipPath
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tempDir)
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to download RAMMap.", "Download Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }
    }
    if (Test-Path $ramMapPath) {
        # Run RAMMap commands to clear memory
        Start-Process -FilePath $ramMapPath -ArgumentList "-Ew -Es -Em -Et -E0" -NoNewWindow -Wait
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("RAMMap tool not found. Please check the script.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }

	
    $statusLabel.Value.Text = "Finalizing..."
    Start-Sleep -Seconds 1
    Update-ProgressBar -step 20

    $statusLabel.Value.Text = "Memory cleared."
}

# Function to Clean Windows
function Clean-Windows {
    param (
        [ref]$statusLabel
    )

    # Start cleaning process
    $statusLabel.Value.Text = "Cleaning Windows..."
    Update-ProgressBar -step 25

    # Simulate cleaning with sleep
    Start-Sleep -Seconds 1
    Update-ProgressBar -step 25

    $statusLabel.Value.Text = "Cleaning temporary files..."
	
    # Define all the paths to clear caches and temporary files
    $tempPath = $env:TEMP
    $globalTempPath = [System.IO.Path]::GetTempPath()
    $userTempPath = $env:TEMP
    $prefetchPath = "$env:windir\Prefetch"
    $windowsUpdatePath = "$env:windir\SoftwareDistribution\Download"
    $thumbnailCachePath = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
    $tempInternetFilesPath = "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"
    $edgeCachePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
    $firefoxCachePath = "$env:APPDATA\Mozilla\Firefox\Profiles"
    $chromeCachePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"

    # Remove files from specified paths
    Try {
        $paths = @(
            $globalTempPath,
            $userTempPath,
            $prefetchPath,
            $windowsUpdatePath,
            $thumbnailCachePath,
            $tempInternetFilesPath,
            $edgeCachePath,
            $firefoxCachePath,
            $chromeCachePath
        )

        foreach ($path in $paths) {
            # Check if the path exists before attempting to delete
            if (Test-Path -Path $path) {
                Write-Host "Cleaning path: $path"
                Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            } else {
                Write-Host "Path does not exist: $path"
            }
        }

        # Clear the Recent Items using Shell Application
        Try {
            (New-Object -ComObject Shell.Application).NameSpace('shell:::{B7D1F2A6-7F03-4F7C-A1EF-F0D7F1F12A5D}').Items() | ForEach-Object { $_.InvokeVerb('delete') } | Out-Null
        } Catch {
            Write-Host "Error clearing recent items: $_"
        }
        } Catch {
        Write-Host "Error during cleanup: $_"
    }

    # Sleep for progress
    Start-Sleep -Seconds 1
    Update-ProgressBar -step 25

    # Finalizing cleanup with Disk Cleanup utility
    $statusLabel.Value.Text = "Finalizing cleanup..."
    $diskCleanupPath = "$env:windir\System32\cleanmgr.exe"
    Start-Process -FilePath $diskCleanupPath -ArgumentList "/sagerun:1" -Wait
    Start-Sleep -Seconds 1
    Update-ProgressBar -step 25

    # Final status
    $statusLabel.Value.Text = "Windows cleaned."
}

# Function to Fix Windows
function Fix-Windows {
    param ([ref]$statusLabel)
    $statusLabel.Value.Text = "Running system fixes..."
    Update-ProgressBar -step 33

    # Simulate fixes with sleep
    Start-Sleep -Seconds 1
    Update-ProgressBar -step 33
	Start-Process -FilePath "chkdsk.exe" -ArgumentList "/scan /perf" -NoNewWindow -Wait

    $statusLabel.Value.Text = "Fixing Windows issues..."
    Start-Sleep -Seconds 1
    Update-ProgressBar -step 34
Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -NoNewWindow -Wait
Start-Process -FilePath "DISM.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -NoNewWindow -Wait
# Running sfc again in case DISM repaired system files
Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -NoNewWindow -Wait
    $statusLabel.Value.Text = "Windows fixed."
}

# Function to Execute Tasks with Progress
function Execute-FunctionWithProgress {
    param (
        [ScriptBlock]$functionToExecute,
        [string]$taskName
    )
    $progressBar.Visible = $true
    $progressBar.Value = 0
    $statusLabel.Text = $taskName
    $functionToExecute.Invoke()
    $progressBar.Visible = $false
}

# Main GUI Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "CSpeed"
$form.Size = New-Object System.Drawing.Size(450, 400)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#3a3a3a")

# Set Icon from SHELL32.dll
$iconPath = [System.IO.Path]::Combine($env:SystemRoot, "System32\SHELL32.dll")
$iconIndex = 54  # Index of the icon you want to use from SHELL32.dll
$icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath)
$form.Icon = $icon

# Status Label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready"
$statusLabel.Size = New-Object System.Drawing.Size(380, 20)
$statusLabel.Location = New-Object System.Drawing.Point(10, 250)
$statusLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Italic)
$statusLabel.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($statusLabel)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Style = 'Continuous'
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Size = New-Object System.Drawing.Size(360, 15)
$progressBar.Location = New-Object System.Drawing.Point(20, 280)
$progressBar.ForeColor = [System.Drawing.Color]::LightGreen
$progressBar.Visible = $false
$form.Controls.Add($progressBar)

# Custom Button Style
function Create-Button {
    param (
        [string]$text,
        [System.Drawing.Point]$location,
        [ScriptBlock]$clickAction
    )

    # Create the button object
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $text
    $button.Size = New-Object System.Drawing.Size(180, 40)
    $button.Location = $location
    $button.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)

    # Set FlatStyle to Flat (default look, no colors changed)
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat

    # Set cursor type when hovering over the button
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand

    # Button click event handler
    $button.Add_Click($clickAction)

    # Return the button
    return $button
}


# Add Buttons with Cool Style
$memoryButton = Create-Button -text "Clear Memory" -location (New-Object System.Drawing.Point(130, 60)) -clickAction {
    Execute-FunctionWithProgress { Clear-Memory ([ref]$statusLabel) } "Clearing Memory..."
}
$form.Controls.Add($memoryButton)

$cleanButton = Create-Button -text "Clean Windows" -location (New-Object System.Drawing.Point(130, 110)) -clickAction {
    Execute-FunctionWithProgress { Clean-Windows ([ref]$statusLabel) } "Cleaning Windows..."
}
$form.Controls.Add($cleanButton)

$fixButton = Create-Button -text "Scan and Fix Windows" -location (New-Object System.Drawing.Point(130, 160)) -clickAction {
    Execute-FunctionWithProgress { Fix-Windows ([ref]$statusLabel) } "Fixing Windows..."
}
$form.Controls.Add($fixButton)

$exitButton = Create-Button -text "Exit" -location (New-Object System.Drawing.Point(130, 210)) -clickAction {
    $form.Close()
}
$form.Controls.Add($exitButton)

# Check if running as Admin and restart if not
Restart-AsAdmin

# Show the form
[void] [System.Windows.Forms.Application]::Run($form)
