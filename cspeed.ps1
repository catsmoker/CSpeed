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

# Function to Clear memory
Function Clear-Memory {
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
Function Fix-Windows {
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
Function Clean-Windows {
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
# Clean Temporary Internet Files
$tempInternetFilesPath = "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"
# Clear Edge Cache
$edgeCachePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
# Clear Firefox Cache
$firefoxCachePath = "$env:APPDATA\Mozilla\Firefox\Profiles"
# Clear Chrome Cache
$chromeCachePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"

    # Run Disk Cleanup
    Log-Message "Running Disk Cleanup..."
    $diskCleanupPath = "$env:windir\System32\cleanmgr.exe"
    Start-Process -FilePath $diskCleanupPath -ArgumentList "/sagerun:1" -Wait

    $elapsedTime = (Get-Date) - $startTime
    Log-Message "Cleanup completed in $($elapsedTime.TotalSeconds) seconds."
}

# Main GUI Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "CS Speed"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Label for Title
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "CS Speed v1 by Catsmoker"
$titleLabel.Size = New-Object System.Drawing.Size(380, 30)
$titleLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
$titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$titleLabel.Location = New-Object System.Drawing.Point(10, 10)
$form.Controls.Add($titleLabel)

# Button to Clear Memory
$memoryButton = New-Object System.Windows.Forms.Button
$memoryButton.Text = "Clear Memory"
$memoryButton.Size = New-Object System.Drawing.Size(180, 30)
$memoryButton.Location = New-Object System.Drawing.Point(100, 60)
$memoryButton.Add_Click({ 
    $memoryButton.Enabled = $false
    Clear-Memory
    $memoryButton.Enabled = $true
})
$form.Controls.Add($memoryButton)

# Button to Clean Windows
$cleanButton = New-Object System.Windows.Forms.Button
$cleanButton.Text = "Clean Windows"
$cleanButton.Size = New-Object System.Drawing.Size(180, 30)
$cleanButton.Location = New-Object System.Drawing.Point(100, 110)
$cleanButton.Add_Click({
    $cleanButton.Enabled = $false
    Clean-Windows
    $cleanButton.Enabled = $true
})
$form.Controls.Add($cleanButton)

# Button to Fix Windows
$fixButton = New-Object System.Windows.Forms.Button
$fixButton.Text = "Scan and Fix Windows"
$fixButton.Size = New-Object System.Drawing.Size(180, 30)
$fixButton.Location = New-Object System.Drawing.Point(100, 160)
$fixButton.Add_Click({
    $fixButton.Enabled = $false
    Fix-Windows
    $fixButton.Enabled = $true
})
$form.Controls.Add($fixButton)

# Button to Exit
$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Text = "Exit"
$exitButton.Size = New-Object System.Drawing.Size(180, 30)
$exitButton.Location = New-Object System.Drawing.Point(100, 210)
$exitButton.Add_Click({ $form.Close() })
$form.Controls.Add($exitButton)

# Check if running as Admin and restart if not
Restart-AsAdmin

# Show the form
[void] [System.Windows.Forms.Application]::Run($form)
