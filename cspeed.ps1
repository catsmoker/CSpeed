# Load Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Logging Function to capture script progress
function Log-Message {
    param (
        [string]$message
    )
    Write-Host $message
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logPath = "$env:TEMP\CS_Speed_Log.txt"
    "$timestamp - $message" | Out-File -Append -FilePath $logPath
}

# Function to Check Admin Privileges
function Check-Admin {
    $adminCheck = [System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    return $adminCheck.IsInRole($adminRole)
}

# Function to Restart Script as Admin
function Restart-AsAdmin {
    if (-not (Check-Admin)) {
        [System.Windows.Forms.MessageBox]::Show("The script needs to be run as Administrator for full functionality.", "Administrator Privileges Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -Wait
        Exit
    }
}

# Function to Clear memory using RAMMap
function Clear-Memory {
    $tempDir = "$env:TEMP\RAMMap"
    $zipPath = "$tempDir\RAMMap.zip"
    $ramMapPath = "$tempDir\RAMMap64.exe"
    
    if (-not (Test-Path $ramMapPath)) {
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir | Out-Null
        }
        
        $url = "https://download.sysinternals.com/files/RAMMap.zip"
        Log-Message "Downloading RAMMap tool..."
        
        try {
            Invoke-WebRequest -Uri $url -OutFile $zipPath
            Log-Message "Download complete."
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to download RAMMap. Please check your internet connection.", "Download Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            Log-Message "Error downloading RAMMap: $_"
            return
        }
        
        Log-Message "Extracting RAMMap..."
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tempDir)
        Log-Message "Extraction complete."
    }

    if (Test-Path $ramMapPath) {
        Log-Message "Clearing memory standby list..."
        Start-Process $ramMapPath -ArgumentList "-Et" -NoNewWindow -Wait
        Log-Message "Memory standby list cleared."
    } else {
        [System.Windows.Forms.MessageBox]::Show("RAMMap tool not found even after download. Please check the script.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }

    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    Log-Message "Memory cleared."
}

# Function to scan and fix Windows issues
function Fix-Windows {
    Log-Message "Starting Windows repair process..."
    
    $startTime = Get-Date
    try {
        Log-Message "Running chkdsk..."
        Start-Process -FilePath "chkdsk.exe" -ArgumentList "/scan /perf" -NoNewWindow -Wait
        Log-Message "chkdsk completed."
        
        Log-Message "Running sfc /scannow..."
        Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -NoNewWindow -Wait
        Log-Message "sfc completed."
        
        Log-Message "Running DISM..."
        Start-Process -FilePath "DISM.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -NoNewWindow -Wait
        Log-Message "DISM completed."
        
        Log-Message "Running sfc again in case DISM repaired system files..."
        Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -NoNewWindow -Wait
        Log-Message "Second sfc scan completed."
    }
    catch {
        Log-Message "Error during Windows repair: $_"
        [System.Windows.Forms.MessageBox]::Show("An error occurred during the Windows repair process. Please check the log for details.", "Repair Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
    
    $elapsedTime = (Get-Date) - $startTime
    Log-Message "Windows repair process completed in $($elapsedTime.TotalMinutes) minutes."
}

# Function to clean up temporary files and caches
function Clean-Windows {
    Log-Message "Starting cleanup process..."
    
    $startTime = Get-Date
    
    # Clean Global Temp Folder
    $globalTempPath = [System.IO.Path]::GetTempPath()
    Log-Message "Clearing global temp folder: $globalTempPath"
    Get-ChildItem -Path $globalTempPath -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    # Clean User Temp Folder
    $userTempPath = $env:TEMP
    Log-Message "Clearing user temp folder: $userTempPath"
    Get-ChildItem -Path $userTempPath -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    # Clean Windows Prefetch Folder
    $prefetchPath = "$env:windir\Prefetch"
    Log-Message "Clearing Windows prefetch folder: $prefetchPath"
    Get-ChildItem -Path $prefetchPath -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    # Empty Recycle Bin
    Log-Message "Emptying Recycle Bin..."
    (New-Object -ComObject Shell.Application).NameSpace(0xA).Items() | ForEach-Object { $_.InvokeVerb("delete") } | Out-Null

    # Clear Windows Update Cache
    $windowsUpdatePath = "$env:windir\SoftwareDistribution\Download"
    Log-Message "Clearing Windows Update cache: $windowsUpdatePath"
    Get-ChildItem -Path $windowsUpdatePath -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    # Clean Windows Thumbnail Cache
    $thumbnailCachePath = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
    Log-Message "Clearing thumbnail cache: $thumbnailCachePath"
    Get-ChildItem -Path $thumbnailCachePath -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    # Clear Browser Caches
    $browserCachePaths = @(
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
        "$env:APPDATA\Mozilla\Firefox\Profiles"
    )
    foreach ($path in $browserCachePaths) {
        if (Test-Path $path) {
            Log-Message "Clearing browser cache: $path"
            Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # Run Disk Cleanup
    Log-Message "Running Disk Cleanup..."
    $diskCleanupPath = "$env:windir\System32\cleanmgr.exe"
    Start-Process -FilePath $diskCleanupPath -ArgumentList "/sagerun:1" -Wait

    $elapsedTime = (Get-Date) - $startTime
    Log-Message "Cleanup completed in $($elapsedTime.TotalSeconds) seconds."
}

# Function to get system information
function Get-SystemInfo {
    $cpu = Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name
    $ram = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object Size, FreeSpace
    $diskSize = [math]::Round($disk.Size / 1GB, 2)
    $diskFree = [math]::Round($disk.FreeSpace / 1GB, 2)
    
    return @"
CPU: $cpu
RAM: $ram GB
Disk (C:): $diskFree GB free of $diskSize GB
"@
}

# Main GUI Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "CS Speed"
$form.Size = New-Object System.Drawing.Size(500, 550)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# Label for Title
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "CS Speed v1 by Catsmoker"
$titleLabel.Size = New-Object System.Drawing.Size(480, 40)
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$titleLabel.Location = New-Object System.Drawing.Point(10, 10)
$titleLabel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($titleLabel)

# System Information Label
$systemInfoLabel = New-Object System.Windows.Forms.Label
$systemInfoLabel.Text = Get-SystemInfo
$systemInfoLabel.Size = New-Object System.Drawing.Size(460, 80)
$systemInfoLabel.Location = New-Object System.Drawing.Point(20, 60)
$systemInfoLabel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$systemInfoLabel.ForeColor = [System.Drawing.Color]::White
$systemInfoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.Controls.Add($systemInfoLabel)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Size = New-Object System.Drawing.Size(460, 20)
$progressBar.Location = New-Object System.Drawing.Point(20, 470)
$progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
$progressBar.ForeColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$form.Controls.Add($progressBar)

# Status Label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready"
$statusLabel.Size = New-Object System.Drawing.Size(460, 20)
$statusLabel.Location = New-Object System.Drawing.Point(20, 500)
$statusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($statusLabel)

# Button to Clear Memory
$memoryButton = New-Object System.Windows.Forms.Button
$memoryButton.Text = "Clear Memory"
$memoryButton.Size = New-Object System.Drawing.Size(220, 40)
$memoryButton.Location = New-Object System.Drawing.Point(20, 160)
$memoryButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$memoryButton.ForeColor = [System.Drawing.Color]::White
$memoryButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$memoryButton.FlatAppearance.BorderSize = 0
$memoryButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$memoryButton.Add_Click({ 
    $memoryButton.Enabled = $false
    $statusLabel.Text = "Clearing memory..."
    $progressBar.Value = 0
    Clear-Memory
    $progressBar.Value = 100
    $statusLabel.Text = "Memory cleared."
    $memoryButton.Enabled = $true
})
$memoryButtonTooltip = New-Object System.Windows.Forms.ToolTip
$memoryButtonTooltip.SetToolTip($memoryButton, "Clear memory standby list using RAMMap.")
$form.Controls.Add($memoryButton)

# Button to Clean Windows
$cleanButton = New-Object System.Windows.Forms.Button
$cleanButton.Text = "Clean Windows"
$cleanButton.Size = New-Object System.Drawing.Size(220, 40)
$cleanButton.Location = New-Object System.Drawing.Point(260, 160)
$cleanButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$cleanButton.ForeColor = [System.Drawing.Color]::White
$cleanButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$cleanButton.FlatAppearance.BorderSize = 0
$cleanButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$cleanButton.Add_Click({
    $cleanButton.Enabled = $false
    $statusLabel.Text = "Cleaning Windows..."
    $progressBar.Value = 0
    Clean-Windows
    $progressBar.Value = 100
    $statusLabel.Text = "Windows cleaned."
    $cleanButton.Enabled = $true
})
$cleanButtonTooltip = New-Object System.Windows.Forms.ToolTip
$cleanButtonTooltip.SetToolTip($cleanButton, "Clean temporary files, caches, and browser data.")
$form.Controls.Add($cleanButton)

# Button to Fix Windows
$fixButton = New-Object System.Windows.Forms.Button
$fixButton.Text = "Scan and Fix Windows"
$fixButton.Size = New-Object System.Drawing.Size(220, 40)
$fixButton.Location = New-Object System.Drawing.Point(20, 220)
$fixButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$fixButton.ForeColor = [System.Drawing.Color]::White
$fixButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$fixButton.FlatAppearance.BorderSize = 0
$fixButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$fixButton.Add_Click({
    $fixButton.Enabled = $false
    $statusLabel.Text = "Scanning and fixing Windows..."
    $progressBar.Value = 0
    Fix-Windows
    $progressBar.Value = 100
    $statusLabel.Text = "Windows scan and fix completed."
    $fixButton.Enabled = $true
})
$fixButtonTooltip = New-Object System.Windows.Forms.ToolTip
$fixButtonTooltip.SetToolTip($fixButton, "Run chkdsk, sfc, and DISM to repair Windows.")
$form.Controls.Add($fixButton)

# Button to View Log
$logButton = New-Object System.Windows.Forms.Button
$logButton.Text = "View Log"
$logButton.Size = New-Object System.Drawing.Size(220, 40)
$logButton.Location = New-Object System.Drawing.Point(260, 220)
$logButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$logButton.ForeColor = [System.Drawing.Color]::White
$logButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$logButton.FlatAppearance.BorderSize = 0
$logButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$logButton.Add_Click({
    $logPath = "$env:TEMP\CS_Speed_Log.txt"
    if (Test-Path $logPath) {
        Start-Process notepad.exe $logPath
    } else {
        [System.Windows.Forms.MessageBox]::Show("No log file found.", "Log File Missing", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})
$logButtonTooltip = New-Object System.Windows.Forms.ToolTip
$logButtonTooltip.SetToolTip($logButton, "View the log file for script progress and errors.")
$form.Controls.Add($logButton)

# Button to Exit
$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Text = "Exit"
$exitButton.Size = New-Object System.Drawing.Size(220, 40)
$exitButton.Location = New-Object System.Drawing.Point(20, 280)
$exitButton.BackColor = [System.Drawing.Color]::FromArgb(200, 50, 50)
$exitButton.ForeColor = [System.Drawing.Color]::White
$exitButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$exitButton.FlatAppearance.BorderSize = 0
$exitButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$exitButton.Add_Click({ $form.Close() })
$exitButtonTooltip = New-Object System.Windows.Forms.ToolTip
$exitButtonTooltip.SetToolTip($exitButton, "Close the application.")
$form.Controls.Add($exitButton)

# Check if running as Admin and restart if not
Restart-AsAdmin

# Show the form
[void] [System.Windows.Forms.Application]::Run($form)
