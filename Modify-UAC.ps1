[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, ParameterSetName = "Enable")]
    [switch]$Enable,

    [Parameter(Mandatory = $true, ParameterSetName = "Disable")]
    [switch]$Disable,

    [Parameter(Mandatory = $true, ParameterSetName = "Help")]
    [switch]$Help
)

$RegistryPathLUA = "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$PropertyNameLUA = "EnableLUA"
$CurrentUserPrompt = "[$(Get-Date -Format "yyyy-MM-dd:HH-mm-ss")] [$([System.Environment]::UserName)@$([System.Environment]::MachineName)]"

function Show-Help 
{
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\ModifyUAC.ps1 -Enable"
    Write-Host "  .\ModifyUAC.ps1 -Disable"
    Write-Host "  .\ModifyUAC.ps1 -Help"
    Write-Host ""
    Write-Host "Description:"
    Write-Host "  -Enable    : Enables UAC"
    Write-Host "  -Disable   : Disables UAC"
    Write-Host "  -Help      : Shows this help message"
    Write-Host ""
    exit 1
}

function Test-RegistryExists
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $true)][string]$RegistryPath,
        [Parameter(Mandatory = $true)][string]$PropertyName
    )

    try 
    {
        if (Test-Path -Path $RegistryPath)
        {
            Write-Output -InputObject "[+] $CurrentUserPrompt Registry path $RegistryPath exists!"

            if (Get-ItemProperty -Path $RegistryPath -Name $PropertyName -ErrorAction SilentlyContinue)
            {
                Write-Output -InputObject "[+] $CurrentUserPrompt Property name $PropertyName exists!"
            }
            else 
            {
                Write-Output -InputObject "[-] $CurrentUserPrompt Property name $PropertyName does not exist!"
                Write-Output -InputObject "[-] $CurrentUserPrompt The script will exit!"
                exit 2
            }
        }
        else 
        {
            Write-Output -InputObject "[-] $CurrentUserPrompt Registry path $RegistryPath does not exist!"
            Write-Output -InputObject "[-] $CurrentUserPrompt The script will exit!"
            exit 2
        }
    }
    catch 
    {
        Write-Output -InputObject "[x] $CurrentUserPrompt An error occured when trying to check if registry exists!"
        Write-Output -InputObject "[x] $CurrentUserPrompt Error: $($_.Exception.Message)"
        Write-Output -InputObject "[x] $CurrentUserPrompt The script will exit!"
        exit 2
    }
}

function Get-RegistryValue
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $true)][string]$RegistryPath,
        [Parameter(Mandatory = $true)][string]$PropertyName
    )

    try 
    {
        $RegistyValueLUA = Get-ItemPropertyValue -Path $RegistryPath -Name $PropertyName -ErrorAction Stop
    }
    catch 
    {
        Write-Output -InputObject "[x] $CurrentUserPrompt An error occured when trying to get the registry value!"
        Write-Output -InputObject "[x] $CurrentUserPrompt Error: $($_.Exception.Message)"
        Write-Output -InputObject "[x] $CurrentUserPrompt The script will exit!"
        exit 3
    }

    return $RegistyValueLUA
}

function Set-RegistryValueUAC
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $true)][string]$RegistryPath,
        [Parameter(Mandatory = $true)][string]$PropertyName,
        [Parameter(Mandatory = $true)][ValidateSet(0,1)][int]$RegistryValue
    )

    try 
    {
        Set-ItemProperty -Path $RegistryPath -Name $PropertyName -Value $RegistryValue -ErrorAction Stop
    }
    catch 
    {
        Write-Output -InputObject "[x] $CurrentUserPrompt An error occured when trying to set the registry value!"
        Write-Output -InputObject "[x] $CurrentUserPrompt Error: $($_.Exception.Message)"
        Write-Output -InputObject "[x] $CurrentUserPrompt The script will exit!"
        exit 4
    }
}

function Update-ChangesUAC
{
    try 
    {
        Write-Output -InputObject "[+] $CurrentUserPrompt Restarting PC in 60 seconds..."
        Start-Sleep -Seconds 60
        Restart-Computer
    }
    catch 
    {
        Write-Output -InputObject "[x] $CurrentUserPrompt An error occured when trying to restart PC for changes to take effect!"
        Write-Output -InputObject "[x] $CurrentUserPrompt Error: $($_.Exception.Message)"
        Write-Output -InputObject "[x] $CurrentUserPrompt The script will exit!"
        exit 6
    }
}

function Enable-UAC
{
    Test-RegistryExists -RegistryPath $RegistryPathLUA -PropertyName $PropertyNameLUA
    $CurrentValueLUA = Get-RegistryValue -RegistryPath $RegistryPathLUA -PropertyName $PropertyNameLUA
    Write-Output -InputObject "CurrentValueLUA: $CurrentValueLUA"
    if ($CurrentValueLUA -eq 1)
    {
        Write-Output -InputObject "[-] $CurrentUserPrompt UAC is already enabled!"
        Write-Output -InputObject "[-] $CurrentUserPrompt The script will exit!"
        exit 0
    }
    else 
    {
        try 
        {
            Set-RegistryValueUAC -RegistryPath $RegistryPathLUA -PropertyName $PropertyNameLUA -RegistryValue 1 -ErrorAction Stop
        }
        catch 
        {
            Write-Output -InputObject "[x] $CurrentUserPrompt An error occured when trying to enable UAC!"
            Write-Output -InputObject "[x] $CurrentUserPrompt Error: $($_.Exception.Message)"
            Write-Output -InputObject "[x] $CurrentUserPrompt The script will exit!"
            exit 5
        }
    }
    $NewValueLUA = Get-RegistryValue -RegistryPath $RegistryPathLUA -PropertyName $PropertyNameLUA
    Write-Output -InputObject "NewValueLUA: $NewValueLUA"
    if ($NewValueLUA -eq 1)
    {
        Write-Output -InputObject "[+] $CurrentUserPrompt UAC has been successfully enabled!"
        Update-ChangesUAC
    }
    else 
    {
        Write-Output -InputObject "[-] $CurrentUserPrompt UAC couldn't be enabled!"
        Write-Output -InputObject "[-] $CurrentUserPrompt The script will exit!"
        exit 7
    }
}

function Disable-UAC
{
    Test-RegistryExists -RegistryPath $RegistryPathLUA -PropertyName $PropertyNameLUA
    $CurrentValueLUA = Get-RegistryValue -RegistryPath $RegistryPathLUA -PropertyName $PropertyNameLUA
    Write-Output -InputObject "CurrentValueLUA: $CurrentValueLUA"
    if ($CurrentValueLUA -eq 0)
    {
        Write-Output -InputObject "[-] $CurrentUserPrompt UAC is already disabled!"
        Write-Output -InputObject "[-] $CurrentUserPrompt The script will exit!"
        exit 0
    }
    else 
    {
        try 
        {
            Set-RegistryValueUAC -RegistryPath $RegistryPathLUA -PropertyName $PropertyNameLUA -RegistryValue 0 -ErrorAction Stop
        }
        catch 
        {
            Write-Output -InputObject "[x] $CurrentUserPrompt An error occured when trying to disable UAC!"
            Write-Output -InputObject "[x] $CurrentUserPrompt Error: $($_.Exception.Message)"
            Write-Output -InputObject "[x] $CurrentUserPrompt The script will exit!"
            exit 5
        }
    }
    $NewValueLUA = Get-RegistryValue -RegistryPath $RegistryPathLUA -PropertyName $PropertyNameLUA
    Write-Output -InputObject "NewValueLUA: $NewValueLUA"
    if ($NewValueLUA -eq 0)
    {
        Write-Output -InputObject "[+] $CurrentUserPrompt UAC has been successfully disabled!"
        Update-ChangesUAC
    }
    else 
    {
        Write-Output -InputObject "[-] $CurrentUserPrompt UAC couldn't be disabled!"
        Write-Output -InputObject "[-] $CurrentUserPrompt The script will exit!"
        exit 7
    }
}

function ModifyRegistryUAC
{
    if ($Help) 
    {
        Show-Help
    }
    elseif ($Enable) 
    {
        Enable-UAC
    }
    else 
    {
        Disable-UAC
    }
}

ModifyRegistryUAC