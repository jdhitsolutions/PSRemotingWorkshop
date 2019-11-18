
Function Get-NetLocalGroup {
    [cmdletbinding()]

    Param(
        [Parameter(Position = 0)]
        [ValidateNotNullorEmpty()]
        [object[]]$Computername = $env:computername,
        [ValidateNotNullorEmpty()]
        [string]$Group = "Administrators",
        [switch]$Asjob
    )

    Write-Verbose "Getting members of local group $Group"

    #define the scriptblock
    $sb = {
        Param([string]$Name = "Administrators")
        $members = net localgroup $Name |
        Where-Object { $_ -AND $_ -notmatch "command completed successfully" } |
        Select-Object -skip 4
        New-Object PSObject -Property @{
            Computername = $env:COMPUTERNAME
            Group        = $Name
            Members      = $members
        }
    } #end scriptblock

    #define a parameter hash table for splatting
    $paramhash = @{
        Scriptblock      = $sb
        HideComputername = $True
        ArgumentList     = $Group
    }

    if ($Computername[0] -is [management.automation.runspaces.pssession]) {
        $paramhash.Add("Session", $Computername)
    }
    else {
        $paramhash.Add("Computername", $Computername)
    }

    if ($asjob) {
        Write-Verbose "Running as job"
        $paramhash.Add("AsJob", $True)
    }

    #run the command
    Invoke-Command @paramhash | Select-Object * -ExcludeProperty RunspaceID

} #end Get-NetLocalGroup