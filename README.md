# CS Speed Utility

CS Speed is a utility designed to improve Windows performance by automating memory clearance, cleaning temporary files and caches, and performing system repairs. It includes both a PowerShell script (`CS_Speed.ps1`) and an executable (`CS_Speed.exe`) for ease of use.

## Features

- **Clear Memory**: Uses Sysinternals RAMMap to clear standby memory, freeing up RAM for active applications.
- **Clean Windows**: Removes temporary files, browser caches, and clears system folders like the Recycle Bin and Windows Update cache.
- **Scan and Fix Windows**: Runs several built-in Windows tools (`chkdsk`, `sfc`, `DISM`) to check and repair system files.
- **Logging**: Captures logs of each operation and saves them in `CS_Speed_Log.txt` for troubleshooting.

## Requirements

- Windows operating system.
- Administrator privileges (the application and script prompt for elevated permissions if not run as Administrator).
- Internet connection to download Sysinternals RAMMap (required for the "Clear Memory" function in the script).

## Usage

### Running the Executable

1. Simply double-click `CS_Speed.exe` to launch the application.
2. Use the GUI to select the desired functions:
   - **Clear Memory**: Clears the memory standby list.
   - **Clean Windows**: Removes various temporary files and caches.
   - **Scan and Fix Windows**: Runs diagnostic and repair tools to address Windows issues.
   - **Exit**: Closes the GUI.

### Running the PowerShell Script

1. Open PowerShell as Administrator.
2. Run the script:
   ```powershell
   .\CS_Speed.ps1

