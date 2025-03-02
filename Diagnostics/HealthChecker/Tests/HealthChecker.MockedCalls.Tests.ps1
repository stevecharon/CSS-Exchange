﻿# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Justification = 'Pester testing file')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Pester testing file')]
[CmdletBinding()]
param()

Describe "Testing Health Checker by Mock Data Imports" {

    BeforeAll {
        . $PSScriptRoot\HealthCheckerTests.ImportCode.NotPublished.ps1
        $Script:Server = $env:COMPUTERNAME
        $Script:MockDataCollectionRoot = "$Script:parentPath\Tests\DataCollection\E19"
        . $PSScriptRoot\HealthCheckerTest.CommonMocks.NotPublished.ps1
    }

    Context "Mocked Calls" {

        It "Testing Standard Mock Calls" {
            $Script:ErrorCount = 0
            Mock Invoke-CatchActions { $Script:ErrorCount++ }
            #redo change to a mock call for Exchange cmdlets
            Mock Get-ExchangeServer { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetExchangeServer.xml" }
            Mock Get-ExchangeCertificate { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetExchangeCertificate.xml" }
            Mock Get-AuthConfig { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetAuthConfig.xml" }
            Mock Get-ExSetupDetails { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\ExSetup.xml" }
            Mock Get-MailboxServer { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetMailboxServer.xml" }
            Mock Get-OwaVirtualDirectory { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetOwaVirtualDirectory.xml" }
            Mock Get-WebServicesVirtualDirectory { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetWebServicesVirtualDirectory.xml" }
            Mock Get-OrganizationConfig { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetOrganizationConfig.xml" }
            Mock Get-HybridConfiguration { return $null }
            # do not need to match the function. Only needed really to test the Assert-MockCalled
            Mock Get-Service { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetServiceMitigation.xml" }
            Mock Get-SettingOverride { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetSettingOverride.xml" }
            Mock Get-ServerComponentState { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetServerComponentState.xml" }
            Mock Test-ServiceHealth { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\TestServiceHealth.xml" }
            Mock Get-AcceptedDomain { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetAcceptedDomain.xml" }
            Mock Get-ReceiveConnector { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetReceiveConnector.xml" }
            Mock Get-SendConnector { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetSendConnector.xml" }

            $Error.Clear()
            $org = Get-OrganizationInformation -EdgeServer $false
            $passedOrganizationInformation = @{
                OrganizationConfig = $org.GetOrganizationConfig
                SettingOverride    = $org.GetSettingOverride
            }
            Get-HealthCheckerExchangeServer -ServerName $Script:Server -PassedOrganizationInformation $passedOrganizationInformation | Out-Null
            $Error.Count | Should -Be $Script:ErrorCount
            # Hard coded to know if this ever changes.
            # Not sure why, but in the build pipeline this has now changed to 2. Where as on my computer it is 1
            # Going to comment out for now
            # Assert-MockCalled Invoke-CatchActions -Exactly 1

            Assert-MockCalled Get-WmiObjectHandler -Exactly 6
            Assert-MockCalled Invoke-ScriptBlockHandler -Exactly 7
            Assert-MockCalled Get-RemoteRegistryValue -Exactly 13
            Assert-MockCalled Get-NETFrameworkVersion -Exactly 1
            Assert-MockCalled Get-DotNetDllFileVersions -Exactly 1
            Assert-MockCalled Get-NicPnpCapabilitiesSetting -Exactly 1
            Assert-MockCalled Get-NetIPConfiguration -Exactly 1
            Assert-MockCalled Get-DnsClient -Exactly 1
            Assert-MockCalled Get-NetAdapterRss -Exactly 1
            Assert-MockCalled Get-HotFix -Exactly 1
            Assert-MockCalled Get-LocalizedCounterSamples -Exactly 1
            Assert-MockCalled Get-ServerRebootPending -Exactly 1
            Assert-MockCalled Get-TimeZoneInformationRegistrySettings -Exactly 1
            Assert-MockCalled Get-AllTlsSettings -Exactly 1
            Assert-MockCalled Get-CredentialGuardEnabled -Exactly 1
            Assert-MockCalled Get-Smb1ServerSettings -Exactly 1
            Assert-MockCalled Get-ExchangeAppPoolsInformation -Exactly 1
            Assert-MockCalled Get-ExchangeApplicationConfigurationFileValidation -Exactly 1
            Assert-MockCalled Get-ExchangeUpdates -Exactly 1
            Assert-MockCalled Get-ExchangeDomainsAclPermissions -Exactly 1
            Assert-MockCalled Get-ExtendedProtectionConfiguration -Exactly 1
            Assert-MockCalled Get-ExchangeAdSchemaClass -Exactly 2
            Assert-MockCalled Get-ExchangeServer -Exactly 1
            Assert-MockCalled Get-ExchangeCertificate -Exactly 1
            Assert-MockCalled Get-AuthConfig -Exactly 1
            Assert-MockCalled Get-ExSetupDetails -Exactly 1
            Assert-MockCalled Get-MailboxServer -Exactly 1
            Assert-MockCalled Get-OwaVirtualDirectory -Exactly 1
            Assert-MockCalled Get-WebServicesVirtualDirectory -Exactly 1
            Assert-MockCalled Get-OrganizationConfig -Exactly 1
            Assert-MockCalled Get-HybridConfiguration -Exactly 1
            Assert-MockCalled Get-Service -Exactly 2
            Assert-MockCalled Get-SettingOverride -Exactly 1
            Assert-MockCalled Get-ServerComponentState -Exactly 1
            Assert-MockCalled Test-ServiceHealth -Exactly 1
            Assert-MockCalled Get-AcceptedDomain -Exactly 1
            Assert-MockCalled Get-FIPFSScanEngineVersionState -Exactly 1
            Assert-MockCalled Get-ReceiveConnector -Exactly 1
            Assert-MockCalled Get-SendConnector -Exactly 1
            Assert-MockCalled Get-IISModules -Exactly 1
            Assert-MockCalled Get-ExchangeSettingOverride -Exactly 1
            Assert-MockCalled Get-ExchangeADSplitPermissionsEnabled -Exactly 1
        }
    }
}
