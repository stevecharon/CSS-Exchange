﻿# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

. $PSScriptRoot\..\..\..\..\Shared\Get-RemoteRegistryValue.ps1
. $PSScriptRoot\..\..\..\..\Shared\Get-ServerRebootPending.ps1
. $PSScriptRoot\..\..\..\..\Shared\VisualCRedistributableVersionFunctions.ps1
. $PSScriptRoot\..\..\..\..\Shared\Invoke-ScriptBlockHandler.ps1
. $PSScriptRoot\..\..\..\..\Shared\TLS\Get-AllTlsSettings.ps1
. $PSScriptRoot\Get-AllNicInformation.ps1
. $PSScriptRoot\Get-CredentialGuardEnabled.ps1
. $PSScriptRoot\Get-HttpProxySetting.ps1
. $PSScriptRoot\Get-OperatingSystemRegistryValues.ps1
. $PSScriptRoot\Get-PageFileInformation.ps1
. $PSScriptRoot\Get-ServerOperatingSystemVersion.ps1
. $PSScriptRoot\Get-Smb1ServerSettings.ps1
. $PSScriptRoot\Get-TimeZoneInformationRegistrySettings.ps1
. $PSScriptRoot\Get-WmiObjectCriticalHandler.ps1
. $PSScriptRoot\Get-WmiObjectHandler.ps1
. $PSScriptRoot\..\..\Helpers\PerformanceCountersFunctions.ps1
function Get-OperatingSystemInformation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Server
    )

    Write-Verbose "Calling: $($MyInvocation.MyCommand)"

    [HealthChecker.OperatingSystemInformation]$osInformation = New-Object HealthChecker.OperatingSystemInformation
    $win32_OperatingSystem = Get-WmiObjectCriticalHandler -ComputerName $Server -Class Win32_OperatingSystem -CatchActionFunction ${Function:Invoke-CatchActions}
    $win32_PowerPlan = Get-WmiObjectHandler -ComputerName $Server -Class Win32_PowerPlan -Namespace 'root\cimv2\power' -Filter "isActive='true'" -CatchActionFunction ${Function:Invoke-CatchActions}
    $currentDateTime = Get-Date
    $lastBootUpTime = [Management.ManagementDateTimeConverter]::ToDateTime($win32_OperatingSystem.lastbootuptime)
    $osInformation.BuildInformation.VersionBuild = $win32_OperatingSystem.Version
    $osInformation.BuildInformation.MajorVersion = (Get-ServerOperatingSystemVersion -OsCaption $win32_OperatingSystem.Caption)
    $osInformation.BuildInformation.FriendlyName = $win32_OperatingSystem.Caption
    $osInformation.BuildInformation.OperatingSystem = $win32_OperatingSystem
    $osInformation.ServerBootUp.Days = ($currentDateTime - $lastBootUpTime).Days
    $osInformation.ServerBootUp.Hours = ($currentDateTime - $lastBootUpTime).Hours
    $osInformation.ServerBootUp.Minutes = ($currentDateTime - $lastBootUpTime).Minutes
    $osInformation.ServerBootUp.Seconds = ($currentDateTime - $lastBootUpTime).Seconds

    if ($null -ne $win32_PowerPlan) {

        if ($win32_PowerPlan.InstanceID -eq "Microsoft:PowerPlan\{8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c}") {
            Write-Verbose "High Performance Power Plan is set to true"
            $osInformation.PowerPlan.HighPerformanceSet = $true
        } else { Write-Verbose "High Performance Power Plan is NOT set to true" }
        $osInformation.PowerPlan.PowerPlanSetting = $win32_PowerPlan.ElementName
    } else {
        Write-Verbose "Power Plan Information could not be read"
        $osInformation.PowerPlan.PowerPlanSetting = "N/A"
    }
    $osInformation.PowerPlan.PowerPlan = $win32_PowerPlan
    $osInformation.PageFile = Get-PageFileInformation -Server $Server
    $osInformation.NetworkInformation.NetworkAdapters = (Get-AllNicInformation -ComputerName $Server -CatchActionFunction ${Function:Invoke-CatchActions} -ComputerFQDN $ServerFQDN)
    foreach ($adapter in $osInformation.NetworkInformation.NetworkAdapters) {

        if (!$adapter.IPv6Enabled) {
            $osInformation.NetworkInformation.IPv6DisabledOnNICs = $true
            break
        }
    }

    $osInformation.NetworkInformation.HttpProxy = Get-HttpProxySetting -Server $Server
    $osInformation.InstalledUpdates.HotFixes = (Get-HotFix -ComputerName $Server -ErrorAction SilentlyContinue) #old school check still valid and faster and a failsafe
    $counterSamples = (Get-LocalizedCounterSamples -MachineName $Server -Counter "\Network Interface(*)\Packets Received Discarded")

    if ($null -ne $counterSamples) {
        $osInformation.NetworkInformation.PacketsReceivedDiscarded = $counterSamples
    }

    $osInformation.ServerPendingReboot = (Get-ServerRebootPending -ServerName $Server -CatchActionFunction ${Function:Invoke-CatchActions})
    $timeZoneInformation = Get-TimeZoneInformationRegistrySettings -MachineName $Server -CatchActionFunction ${Function:Invoke-CatchActions}
    $osInformation.TimeZone.DynamicDaylightTimeDisabled = $timeZoneInformation.DynamicDaylightTimeDisabled
    $osInformation.TimeZone.TimeZoneKeyName = $timeZoneInformation.TimeZoneKeyName
    $osInformation.TimeZone.StandardStart = $timeZoneInformation.StandardStart
    $osInformation.TimeZone.DaylightStart = $timeZoneInformation.DaylightStart
    $osInformation.TimeZone.DstIssueDetected = $timeZoneInformation.DstIssueDetected
    $osInformation.TimeZone.ActionsToTake = $timeZoneInformation.ActionsToTake
    $osInformation.TimeZone.CurrentTimeZone = Invoke-ScriptBlockHandler -ComputerName $Server `
        -ScriptBlock { ([System.TimeZone]::CurrentTimeZone).StandardName } `
        -ScriptBlockDescription "Getting Current Time Zone" `
        -CatchActionFunction ${Function:Invoke-CatchActions}
    $osInformation.TLSSettings = Get-AllTlsSettings -MachineName $Server -CatchActionFunction ${Function:Invoke-CatchActions}
    $osInformation.VcRedistributable = Get-VisualCRedistributableInstalledVersion -ComputerName $Server -CatchActionFunction ${Function:Invoke-CatchActions}
    $osInformation.CredentialGuardEnabled = Get-CredentialGuardEnabled -Server $Server
    $osInformation.Smb1ServerSettings = Get-Smb1ServerSettings -ServerName $Server -CatchActionFunction ${Function:Invoke-CatchActions}
    $osInformation.RegistryValues = Get-OperatingSystemRegistryValues -MachineName $Server -CatchActionFunction ${Function:Invoke-CatchActions}

    Write-Verbose "Exiting: $($MyInvocation.MyCommand)"
    return $osInformation
}
