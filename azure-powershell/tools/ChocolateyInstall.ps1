﻿$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

$packageName = 'azure-powershell'
$moduleVersion = [version]'5.4.0'
$url = 'https://github.com/Azure/azure-powershell/releases/download/v5.4.0-February2018/azure-powershell.5.4.0.msi'
$checksum = '09E331C99F7ECE8E7CD9BD473B029BD2B18067326BE4C803D54BF3A35EB4C9C1'
$checksumType = 'sha256'

. (Join-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Path) -ChildPath helpers.ps1)

Ensure-RequiredPowerShellVersionPresent -RequiredVersion '3.0'

if (Test-AzurePowerShellInstalled -RequiredVersion $moduleVersion)
{
    return
}

$scriptDirectory = $PSScriptRoot # safe to use because we test for PS 3.0+ earlier
$originalMsiLocalPath = Join-Path -Path $scriptDirectory -ChildPath "azure-powershell.${moduleVersion}.msi"

$downloadArguments = @{
    packageName = $packageName
    fileFullPath = $originalMsiLocalPath
    url = $url
    checksum = $checksum
    checksumType = $checksumType
}

Set-StrictMode -Off # unfortunately, builtin helpers are not guaranteed to be strict mode compliant
Get-ChocolateyWebFile @downloadArguments | Out-Null
Set-StrictMode -Version 2

Write-Host 'Modifying the Azure PowerShell installer to prevent it from killing powershell.exe and adjusting the execution policy'
$transformLocalPath = New-AzurePowerShellInstallerTransform -OriginalMsiPath $originalMsiLocalPath -ActionsToRemove @('WixCloseApplications', 'SetExecutionPolicy')

$instArguments = @{
    packageName = $packageName
    installerType = 'msi'
    file = $originalMsiLocalPath
    silentArgs = '/Quiet /NoRestart /Log "{0}\{1}_{2:yyyyMMddHHmmss}.log" TRANSFORMS="{3}"' -f $Env:TEMP, $packageName, (Get-Date), $transformLocalPath
    validExitCodes = @(
        0, # success
        3010 # success, restart required
    )
}

Set-StrictMode -Off
Install-ChocolateyInstallPackage @instArguments

Write-Warning 'You may need to close and reopen PowerShell before the Azure PowerShell modules become available.'