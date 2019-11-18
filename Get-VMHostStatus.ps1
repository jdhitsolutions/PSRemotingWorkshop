#requires -version 5.1

Function Get-VMHostStatus {
<#
.SYNOPSIS
Get a summary of a Hyper-V Host
.DESCRIPTION
Use this command to get a summary snapshot of a Hyper-V Host. The command uses PowerShell remoting to gather system information, performance counter data and Hyper-V settings. It does not require the Hyper-V module unless you are running it on the local host, which is the default.
.PARAMETER Computername
Enter the name of the Hyper-V host.
.PARAMETER Credential
Enter an alternate credential in the form domain\username or machine\username.
.EXAMPLE
PS C:\> Get-VMHostStatus -Computername HV01

Computername                    : HV01
Uptime                          : 13.20:01:31.7222927
PctProcessorTime                : 18.1370520347218
TotalMemoryGB                   : 128
PctMemoryFree                   : 34.79
TotalVMs                        : 24
RunningVMs                      : 18
OffVMs                          : 5
SavedVMs                        : 0
PausedVMs                       : 1
OtherVMs                        : 0
Critical                        : 0
Healthy                         : 24
TotalAssignedMemoryGB           : 32.896484375
TotalDemandMemoryGB             : 20.80078125
TotalPctDemand                  : 18.18
PctFreeDisk                     : 47.5408662499084
VMSwitchBytesSec                : 926913.772872509
VMSwitchPacketsSec              : 24.98692048485236
LogicalProcPctGuestRuntime      : 12.15894683010222
LogicalProcPctHypervisorRuntime : 2.710086619427829
TotalProcesses                  : 271

.INPUTS
System.String
.OUTPUTS
Custom object
.NOTES
Learn more about PowerShell: http://jdhitsolutions.com/blog/essential-powershell-resources/
.LINK
Get-Counter
.lINK
Get-VMHost
.LINK
Get-Volume
.LINK
Get-VM
.LINK
Invoke-Command
#>

    [cmdletbinding(DefaultParameterSetName = "Computername")]
    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, HelpMessage = "Enter the name of the Hyper-V host.", ParameterSetName = "Computername")]
        [ValidateNotNullorEmpty()]
        [string[]]$Computername,
        [Parameter(ValueFromPipelineByPropertyName, HelpMessage = "Enter an alternate credential in the form domain\username or machine\username.", ParameterSetName = "Computername")]
        [PSCredential]$Credential,
        [Parameter(ParameterSetName = "Computername")]
        [ValidateSet('Default', 'Basic', 'Credssp', 'Digest', 'Kerberos', 'Negotiate', 'NegotiateWithImplicitCredential')]
        [ValidateNotNullorEmpty()]
        [string]$Authentication = "default",
        [Parameter(ParameterSetName = "Computername")]
        [switch]$UseSSL,
        [Parameter(ParameterSetName = "Computername")]
        [System.Management.Automation.Remoting.PSSessionOption]$SessionOption,
        [Parameter(Position = 0,ParameterSetName = "session", ValueFromPipeline)]
        [System.Management.Automation.Runspaces.PSSession[]]$Session

    )

    Begin {
        Write-Verbose "[BEGIN  ] Starting: $($MyInvocation.Mycommand)"

        $progParams = @{
            Activity         = $MyInvocation.MyCommand
            Status           = "Preparing..."
            CurrentOperation = ""
            PercentComplete  = 0
        }

        if (-not $PSBoundParameters.ContainsKey("ErrorAction")) {
            $PSBoundParameters.add("ErrorAction", "Stop")
        }

        #get all the data via a remote scriptblock
        $sb = {
            #define a nested function to parse counter samples
            Function _getCooked {
                Param(
                    [Microsoft.PowerShell.Commands.GetCounter.PerformanceCounterSample[]]$Sample,
                    [string]$Counter
                )
                (($Sample).where( {$_.path -match "$counter"})).cookedValue
            } #close _getCooked

            Try {

                ($using:progParams).CurrentOperation = "Getting VMHost"
                ($using:progParams).PercentComplete = 20
                Write-Progress @using:progparams
                $vHost = Get-VMHost -ErrorAction stop

                ($using:progParams).CurrentOperation = "Getting OS properties"
                ($using:progParams).PercentComplete = 30
                Write-Progress @using:progParams
                $os = Get-CimInstance -ClassName Win32_OperatingSystem -property LastBootUpTime, FreePhysicalMemory, TotalVisibleMemorySize -ErrorAction Stop

                #get volume with default virtual hard disk path to check space
                ($using:progParams).CurrentOperation = "Getting virtual hard disk path volume"
                ($using:progParams).PercentComplete = 40
                Write-Progress @using:progParams

                $vol = Get-Volume (Split-Path $vhost.VirtualHardDiskPath).Substring(0, 1) -ErrorAction Stop

                ($using:progParams).CurrentOperation = "Getting virtual machines"
                ($using:progParams).PercentComplete = 60
                Write-Progress @using:progParams

                $vms = Get-VM

                ($using:progParams).CurrentOperation = "Calculating VM Usage"
                ($using:progParams).PercentComplete = 75

                Write-Progress @using:progParams

                $vmusage = ($vms).Where( {$_.state -eq 'running'}) | Select-Object Name,
                @{Name = "Status"; Expression = {$_.MemoryStatus}},
                @{Name = "MemAssignGB"; Expression = {$_.MemoryAssigned / 1GB}},
                @{Name = "PctAssignTotal"; Expression = {[math]::Round(($_.memoryAssigned / ($vhost.memoryCapacity)) * 100, 2)}},
                @{Name = "MemDemandGB"; Expression = {$_.MemoryDemand / 1GB}},
                @{Name = "PctDemandTotal"; Expression = {[math]::Round(($_.memoryDemand / ($vhost.MemoryCapacity)) * 100, 2)}}

                #get performance counter data
                ($using:progParams).CurrentOperation = "Getting performance counter data"
                ($using:progParams).PercentComplete = 80
                Write-Progress @using:progParams

                $counters = Get-Counter -counter '\processor(_total)\% processor time',
                '\hyper-v virtual machine health summary\health critical',
                '\hyper-v virtual machine health summary\health ok',
                "\hyper-v virtual switch(*)\bytes/sec",
                "\hyper-v virtual switch(*)\packets/sec",
                '\system\processes',
                '\hyper-v hypervisor logical processor(_total)\% guest run time',
                '\hyper-v hypervisor logical processor(_total)\% hypervisor run time'

                #write result as a custom object
                [pscustomobject]@{
                    Computername                    = $vHost.Name
                    Uptime                          = (Get-Date) - $os.LastBootUpTime
                    PctProcessorTime                = _getCooked -sample $counters.countersamples -counter '% processor time'
                    TotalMemoryGB                   = $vhost.MemoryCapacity / 1GB -as [int]
                    PctMemoryFree                   = [Math]::Round(($os.FreePhysicalMemory / $os.totalVisibleMemorySize) * 100, 2)
                    TotalVMs                        = $vms.count
                    RunningVMs                      = $vms.where( {$_.state -eq 'running'}).count
                    OffVMs                          = $vms.where( {$_.state -eq 'off'}).count
                    SavedVMs                        = $vms.where( {$_.state -eq 'Saved'}).count
                    PausedVMs                       = $vms.where( {$_.state -eq 'Paused'}).count
                    OtherVMs                        = $vms.where( {$_.state -notmatch "running|off|saved|Paused"}).count
                    Critical                        = _getCooked -sample $counters.CounterSamples -counter "health critical"
                    Healthy                         = _getCooked -sample $counters.countersamples -counter 'health ok'
                    TotalAssignedMemoryGB           = ($vmusage | Measure-Object -Property MemAssignGB -sum).sum
                    TotalDemandMemoryGB             = ($vmusage | Measure-Object -Property MemDemandGB -sum).sum
                    TotalPctDemand                  = ($vmusage | Measure-Object -Property PctDemandTotal -sum).sum
                    PctFreeDisk                     = ($vol.SizeRemaining / $vol.size) * 100
                    VMSwitchBytesSec                = (_getCooked -sample $counters.countersamples -counter 'bytes/sec' | Measure-Object -sum).sum
                    VMSwitchPacketsSec              = (_getCooked -sample $counters.countersamples -counter 'packets/sec' | Measure-Object -sum).sum
                    LogicalProcPctGuestRuntime      = _getCooked -sample $counters.countersamples -counter 'guest run time'
                    LogicalProcPctHypervisorRuntime = _getCooked -sample $counters.countersamples -counter 'hypervisor run time'
                    TotalProcesses                  = _getCooked -sample $counters.countersamples -counter '\\system\\processes'
                }
            } #try
            catch {
                Throw $_
            } #catch
        } #close scriptblock

    } #begin

    Process {
        Write-Verbose "[PROCESS] Using parameter set $($pscmdlet.ParameterSetName)"
        If ($PSCmdlet.ParameterSetName -eq 'session') {
            $ps = $Session
        }
        else {
            Try {
                Write-Verbose "[PROCESS] Creating a PSSession to $($Computername -join ',')"
                $progParams.CurrentOperation = "Creating temporary PSSession"
                $progParams.PercentComplete = 5
                Write-Progress @progParams
                $ps = New-PSSession @PSBoundParameters
                #define a variable to indicate these sessions were created on an ad hoc basis
                #so they can be removed.
                $adhoc = $True
            }
            Catch {
                Throw $_
                #make sure we bail out is the session can't be created
                Return
            }
        }

        foreach ($session in $ps) {

            Write-Verbose "[PROCESS] Querying $($session.computername.toUpper())"
            $progParams.status = $session.computername.toUpper()
            $progParams.CurrentOperation = "Invoking scriptblock"
            $progParams.PercentComplete = 10
            Write-Progress @progParams

            Invoke-Command -ScriptBlock $sb -Session $session -HideComputerName |
                Select-Object -Property * -ExcludeProperty RunspaceID, PSShowComputername, PSComputername

        } #foreach
    } #process

    End {
        $progParams.CurrentOperation = "Cleaning up"
        $progParams.PercentComplete = 95

        Write-Progress @progParams

        if ($adhoc) {
            Write-Verbose "[END    ] Cleaning up sessions"
            Remove-PSSession $ps
        }
        $progParams.percentComplete =100
        $progParams.Add("Completed",$True)
        Write-Progress @progParams
        Write-Verbose "[END    ] Ending: $($MyInvocation.Mycommand)"
    } #end

} #close function

<#

CounterSetName                               MachineName
--------------                               -----------
Hyper-V VM Virtual Device Pipe IO            .
Hyper-V Virtual Machine Health Summary       .
Hyper-V VM Vid Partition                     .
Hyper-V VM Vid Numa Node                     .
Hyper-V Virtual Switch                       .
Hyper-V Virtual Machine Bus Provider Pipes   .
Hyper-V Virtual Storage Device               .
Hyper-V VM Save, Snapshot, and Restore       .
Hyper-V Dynamic Memory Balancer              .
Hyper-V Dynamic Memory VM                    .
Hyper-V Virtual SMB                          .
Hyper-V Virtual Machine Bus                  .
Hyper-V Configuration                        .
Hyper-V VM Live Migration                    .
Hyper-V Legacy Network Adapter               .
Hyper-V Worker Virtual Processor             .
Hyper-V Dynamic Memory Integration Service   .
Hyper-V Virtual Network Adapter VRSS         .
Hyper-V Virtual IDE Controller (Emulated)    .
Hyper-V Virtual Network Adapter              .
Hyper-V Virtual Machine Bus Pipes            .
Hyper-V Replica VM                           .
Hyper-V VM Remoting                          .
Hyper-V Hypervisor Virtual Processor         .
Hyper-V Hypervisor Partition                 .
Hyper-V Virtual Network Adapter Drop Reasons .
Hyper-V Hypervisor Root Virtual Processor    .
Hyper-V Hypervisor Root Partition            .
Hyper-V Hypervisor                           .
Hyper-V Hypervisor Logical Processor         .
Hyper-V Virtual Switch Processor             .
Hyper-V Virtual Switch Port                  .


#>
