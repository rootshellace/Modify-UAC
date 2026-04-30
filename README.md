# Modify-UAC by rootshellace

This is a PowerShell script which enables or disables UAC in Windows. It uses simple switch parameters so you don't have to change anything manually.

## Prerequisites

Because it modifies registry keys under `HKLM`, you must run PowerShell with Administrator privileges. Without elevated or specific rights, the script will fail to apply changes.

## Usage

You must provide exactly one parameter when running the script. Passing multiple parameters or invalid ones will result in an error from PowerShell.

The script accepts the following parameters:

- `-Enable` : Enables UAC
- `-Disable` : Disables UAC
- `-Help` : Displays usage instructions

Example of output when running it with `-Help`:

```powershell
PS C:\> .\Modify-UAC.ps1 -Help

Usage:
  .\Modify-UAC.ps1 -Enable
  .\Modify-UAC.ps1 -Disable
  .\Modify-UAC.ps1 -Help

Description:
  -Enable    : Enables UAC
  -Disable   : Disables UAC
  -Help      : Shows this help message

```
