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
    Write-Host -Object ""
    Write-Host -Object "Usage:" -ForegroundColor Cyan
    Write-Host -Object "  .\Modify-UAC.ps1 -Enable" -ForegroundColor Cyan
    Write-Host -Object "  .\Modify-UAC.ps1 -Disable" -ForegroundColor Cyan
    Write-Host -Object "  .\Modify-UAC.ps1 -Help" -ForegroundColor Cyan
    Write-Host -Object ""
    Write-Host -Object "Description:" -ForegroundColor White
    Write-Host -Object "  -Enable    : Enables UAC" -ForegroundColor White
    Write-Host -Object "  -Disable   : Disables UAC" -ForegroundColor White
    Write-Host -Object "  -Help      : Shows this help message" -ForegroundColor White
    Write-Host -Object ""
    exit 1
}

function Show-FormattedHeader
{
    param 
    (
        [Parameter(Mandatory = $true)][string]$HeaderMessage
    )

    $FullHeader = ">>> " + $HeaderMessage + " <<<"
    $BarLine = "-" * $FullHeader.Length

    Write-Host -Object ""
    Write-Host -Object $FullHeader -ForegroundColor White
    Write-Host -Object $BarLine -ForegroundColor White
    Write-Host
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
            Write-Host -Object "[+] $CurrentUserPrompt Registry path $RegistryPath exists!" -ForegroundColor Green

            if (Get-ItemProperty -Path $RegistryPath -Name $PropertyName -ErrorAction SilentlyContinue)
            {
                Write-Host -Object "[+] $CurrentUserPrompt Property name $PropertyName exists!" -ForegroundColor Green
            }
            else 
            {
                Write-Host -Object "[*] $CurrentUserPrompt Property name $PropertyName does not exist!" -ForegroundColor Yellow
                Write-Host -Object "[*] $CurrentUserPrompt The script will exit!" -ForegroundColor Yellow
                exit 2
            }
        }
        else 
        {
            Write-Host -Object "[*] $CurrentUserPrompt Registry path $RegistryPath does not exist!" -ForegroundColor Yellow
            Write-Host -Object "[*] $CurrentUserPrompt The script will exit!" -ForegroundColor Yellow
            exit 2
        }
    }
    catch 
    {
        Write-Host -Object "[x] $CurrentUserPrompt An error occured when trying to check if registry exists!" -ForegroundColor Red
        Write-Host -Object "[x] $CurrentUserPrompt Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host -Object "[x] $CurrentUserPrompt The script will exit!" -ForegroundColor Red
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
        Write-Host -Object "[x] $CurrentUserPrompt An error occured when trying to get the registry value!" -ForegroundColor Red
        Write-Host -Object "[x] $CurrentUserPrompt Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host -Object "[x] $CurrentUserPrompt The script will exit!" -ForegroundColor Red
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
        Write-Host -Object "[x] $CurrentUserPrompt An error occured when trying to set the registry value!" -ForegroundColor Red
        Write-Host -Object "[x] $CurrentUserPrompt Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host -Object "[x] $CurrentUserPrompt The script will exit!" -ForegroundColor Red
        exit 4
    }
}


function Enable-UAC
{
    Show-FormattedHeader -HeaderMessage "Check Registry"
    Test-RegistryExists -RegistryPath $RegistryPathLUA -PropertyName $PropertyNameLUA
    
    Show-FormattedHeader -HeaderMessage "Get Current Registry Value"
    $CurrentValueLUA = Get-RegistryValue -RegistryPath $RegistryPathLUA -PropertyName $PropertyNameLUA
    Write-Host -Object "[+] $CurrentUserPrompt Current value for $PropertyNameLUA : $CurrentValueLUA" -ForegroundColor Green

    if ($CurrentValueLUA -eq 1)
    {
        Write-Host -Object "[*] $CurrentUserPrompt UAC is already enabled!" -ForegroundColor Yellow
        Write-Host -Object "[*] $CurrentUserPrompt The script will exit!" -ForegroundColor Yellow
        exit 0
    }
    else 
    {
        try 
        {
            Show-FormattedHeader -HeaderMessage "Set New Registry Value"
            Set-RegistryValueUAC -RegistryPath $RegistryPathLUA -PropertyName $PropertyNameLUA -RegistryValue 1 -ErrorAction Stop

            $NewValueLUA = Get-RegistryValue -RegistryPath $RegistryPathLUA -PropertyName $PropertyNameLUA
            Write-Host -Object "[+] $CurrentUserPrompt New Value for $PropertyNameLUA : $NewValueLUA" -ForegroundColor Green

            if ($NewValueLUA -eq 1)
            {
                Write-Host -Object "[+] $CurrentUserPrompt UAC has been successfully enabled!" -ForegroundColor Green
                Write-Host -Object "[+] $CurrentUserPrompt For changes to take effect, you must restart the PC!" -ForegroundColor Green
            }
            else 
            {
                Write-Host -Object "[*] $CurrentUserPrompt UAC couldn't be enabled!" -ForegroundColor Red
                Write-Host -Object "[*] $CurrentUserPrompt The script will exit!" -ForegroundColor Red
                exit 7
            }
        }
        catch 
        {
            Write-Host -Object "[x] $CurrentUserPrompt An error occured when trying to enable UAC!" -ForegroundColor Red
            Write-Host -Object "[x] $CurrentUserPrompt Error: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host -Object "[x] $CurrentUserPrompt The script will exit!" -ForegroundColor Red
            exit 5
        }
    }
}

function Disable-UAC
{
    Show-FormattedHeader -HeaderMessage "Check Registry"
    Test-RegistryExists -RegistryPath $RegistryPathLUA -PropertyName $PropertyNameLUA
    
    Show-FormattedHeader -HeaderMessage "Get Current Registry Value"
    $CurrentValueLUA = Get-RegistryValue -RegistryPath $RegistryPathLUA -PropertyName $PropertyNameLUA
    Write-Host -Object "[+] $CurrentUserPrompt Current value for $PropertyNameLUA : $CurrentValueLUA" -ForegroundColor Green

    if ($CurrentValueLUA -eq 0)
    {
        Write-Host -Object "[*] $CurrentUserPrompt UAC is already disabled!" -ForegroundColor Yellow
        Write-Host -Object "[*] $CurrentUserPrompt The script will exit!" -ForegroundColor Yellow
        exit 0
    }
    else 
    {
        try 
        {
            Show-FormattedHeader -HeaderMessage "Set New Registry Value"
            Set-RegistryValueUAC -RegistryPath $RegistryPathLUA -PropertyName $PropertyNameLUA -RegistryValue 0 -ErrorAction Stop

            $NewValueLUA = Get-RegistryValue -RegistryPath $RegistryPathLUA -PropertyName $PropertyNameLUA
            Write-Host -Object "[+] $CurrentUserPrompt New Value for $PropertyNameLUA : $NewValueLUA" -ForegroundColor Green

            if ($NewValueLUA -eq 0)
            {
                Write-Host -Object "[+] $CurrentUserPrompt UAC has been successfully disabled!" -ForegroundColor Green
                Write-Host -Object "[+] $CurrentUserPrompt For changes to take effect, you must restart the PC!" -ForegroundColor Green
            }
            else 
            {
                Write-Host -Object "[*] $CurrentUserPrompt UAC couldn't be disabled!" -ForegroundColor Red
                Write-Host -Object "[*] $CurrentUserPrompt The script will exit!" -ForegroundColor Red
                exit 7
            }
        }
        catch 
        {
            Write-Host -Object "[x] $CurrentUserPrompt An error occured when trying to disabled UAC!" -ForegroundColor Red
            Write-Host -Object "[x] $CurrentUserPrompt Error: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host -Object "[x] $CurrentUserPrompt The script will exit!" -ForegroundColor Red
            exit 5
        }
    }
}

function ModifyRegistryUAC
{
    if ($Enable) 
    {
        Enable-UAC
    }
    elseif ($Disable) 
    {
        Disable-UAC
    }
    else 
    {
        Show-Help
    }
}

ModifyRegistryUAC