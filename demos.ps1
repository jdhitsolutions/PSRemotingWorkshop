return "This is a guided walkthrough script"

#region PowerShell Remoting Fundamentals

#wsman and remoting requirements
#enabling remoting
#Test-WSMan
#Test-NetConnection

#region using Group Policy

    #start WinRM
    #create endpoints
    #Create firewall rules
     <#
     
Name                  : WINRM-HTTP-In-TCP-NoScope
DisplayName           : Windows Remote Management (HTTP-In)
Description           : Inbound rule for Windows Remote Management via WS-Management. [TCP 5985]
DisplayGroup          : Windows Remote Management
Group                 : @FirewallAPI.dll,-30267
Enabled               : True
Profile               : Domain, Private
Platform              : {}
Direction             : Inbound
Action                : Allow
EdgeTraversalPolicy   : Block
LooseSourceMapping    : False
LocalOnlyMapping      : False
Owner                 : 
PrimaryStatus         : OK
Status                : The rule was parsed successfully from the store. (65536)
EnforcementStatus     : NotApplicable
PolicyStoreSource     : PersistentStore
PolicyStoreSourceType : Local

Name                  : WINRM-HTTP-In-TCP
DisplayName           : Windows Remote Management (HTTP-In)
Description           : Inbound rule for Windows Remote Management via WS-Management. [TCP 5985]
DisplayGroup          : Windows Remote Management
Group                 : @FirewallAPI.dll,-30267
Enabled               : True
Profile               : Public
Platform              : {}
Direction             : Inbound
Action                : Allow
EdgeTraversalPolicy   : Block
LooseSourceMapping    : False
LocalOnlyMapping      : False
Owner                 : 
PrimaryStatus         : OK
Status                : The rule was parsed successfully from the store. (65536)
EnforcementStatus     : NotApplicable
PolicyStoreSource     : PersistentStore
PolicyStoreSourceType : Local
#> 

#or use a PowerShell Startup Script
if ( (Get-Service -Name winrm).StartType -eq 'Disabled' -OR (-Not (Test-WSMan))) {
    write-host "Remoting needs to be enabled"
    Enable-PSRemoting -Force
}

#endregion

#limitations
#TrustedHosts
#one-to-one

#one-to-many

#using PSSessions

#discovering who is connected
psedit .\get-remotesession.ps1

help about_remote*
help about_pssession*

#endregion

#region Configuring SSL

psedit .\Configure-SSLRemoting.ps1

#endregion

#region The Dreaded 2nd Hop

#credssp
psedit .\demo-credssp.ps1

#kerberos delegation
psedit .\Demo-KerberosDelegation.ps1

#endregion

#region Using disconnected sessions

help about_Remote_Disconnected_Sessions

#endregion

#region Remoting at Scale

#Invoke-Command
#running scripts
#$using:
#copying files over remoting

#endregion

#region Creating Constrained Remoting Endpoints

help about_Session

Get-PSSessionConfiguration
Get-PSSessionConfiguration -Name microsoft.powershell | Select-Object *

Enter-PSSession -VMName srv2 -Credential $artd
help New-PSSessionConfigurationFile -online

$newEP = ".\Restricted.pssc"

$params = @{
    Path                = $newEP
    Author              = "Art Deco"
    CompanyName         = "Company.pri"
    Description         = "A restricted endpoint"
    ExecutionPolicy     = "restricted"
    LanguageMode        = "NoLanguage"
    MountUserDrive      = $True
    RunAsVirtualAccount = $True
    TranscriptDirectory = "c:\Transcripts"
    VisibleCmdlets      = 'Get-Service', 'Get-Process', 'Exit-PSSession', 'Get-Command', 'Get-FormatData', 'Out-File', 'Out-Default', 'Select-Object', 'Measure-Object'
    VisibleFunctions    = 'Get-Volume'
}

<#
required visible cmdlets
'Exit-PSSession','Get-Command','Get-FormatData','Out-File','Out-Default','Select-Object','Measure-Object'
#>

New-PSSessionConfigurationFile @params

Get-Content $newEP

#need to create the transcript folder
If (-Not (Test-Path c:\Transcripts)) {
    mkdir C:\Transcripts
}

help Register-PSSessionConfiguration

# give this group access
# get-adgroup IT | get-adgroupmember
# get-aduser maryl -Properties memberof

#replace the SID
$sddl = "O:NSG:BAD:P(A;;GA;;;BA)(A;;GA;;;IU)(A;;GA;;;RM)(A;;GXGR;;;S-1-5-21-3873872113-3455461782-542000861-1145)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)"
Register-PSSessionConfiguration -Path $newEP -Name Restricted -SecurityDescriptorSddl $sddl

#or use -ShowSecurityDescriptorUI parameter

Get-PSSessionConfiguration restricted | select *

exit

Enter-PSSession -ComputerName srv2 -Credential company\maryl -ConfigurationName restricted

Get-Command -noun pssessionconfiguration

#will revisit this with JEA
#endregion

#region Getting started with Just Enough Administration

cd p:\techmentor2019\JEA
invoke-item .\hicks-psjea.pptx

#endregion

#region SSH Remoting with PowerShell Core/7


#endregion

#region What about you?

#what are your remoting questions or problems?

#endregion