#requires -version 5.1
#requires -module CimCmdlets

Function Get-PSRemoteSession {

    [cmdletbinding()]
    [alias("gpsr")]
    Param(
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullorEmpty()]
        [Alias("CN", "Name", "PSComputername")]
        [string[]]$Computername = $env:COMPUTERNAME
    )

    Begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand)"
    } #begin

    Process {
        foreach ($computer in $computername) {

            Write-Verbose "Querying $computer"
            Try {

                #use CIM to remotely query the computer
                #create a hashtable of parameter values to splat to Get-CimInstance
                $paramHash = @{
                    classname    = 'win32_process'
                    filter       = "name='wsmprovhost.exe'"
                    computername = $computer
                    ErrorAction  = 'Stop'
                }

                $data = Get-CimInstance @paramHash

            } #try

            Catch {
                Write-Warning "Could not query $computer. $($_.Exception.Message)"
            } #catch

            if ($data) {
                Write-Verbose "Found $(($data | Measure-Object).count) remoting sessions on $computer"

                foreach ($item in $data) {
                    #get process owner
                    $owner = $item | Invoke-CimMethod -MethodName GetOwner
                    [pscustomobject]@{
                        PSTypeName   = "PSRemoteConnection"
                        Computername = $item.PSComputername.toUpper()
                        ProcessID    = $item.ProcessID
                        Created      = $item.CreationDate
                        Runtime      = (Get-Date) - $item.creationdate
                        Username     = "$($owner.domain)\$($owner.user)"
                    }
                } #foreach

                #reset the variable for the next computer
                Remove-Variable -Name data
            } #if $data

        } #foreach computer
    } #process

    End {
        Write-verbose "Ending $($MyInvocation.MyCommand)"
    } #end

} #end function

Update-FormatData -AppendPath $PSScriptRoot\psremoteconnection.format.ps1xml