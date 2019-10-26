
return "This is a walk through demo"

#read https://blogs.technet.microsoft.com/ashleymcglone/2016/08/30/powershell-remoting-kerberos-double-hop-solved-securely/

# run this on a domain member
# this needs the AD module

$a = $env:computername
$b = 'SRV1'
$c = 'SRV2'

$server = Get-ADComputer $c
$client = Get-ADComputer $b

# Get-CimInstance Win32_Service -Filter 'Name="winrm"' -ComputerName $client.name | Select Startname
#setup the delegation
Set-ADComputer -Identity $Server -PrincipalsAllowedToDelegateToAccount $client

#verify
Get-ADComputer -Identity $Server -Properties PrincipalsAllowedToDelegateToAccount

#need to purge tickets due to 15min SPN negative cache
Invoke-Command -ComputerName $client.Name  -ScriptBlock {
    klist purge -li 0x3e7
}
#or reboot $B

Enter-PSSession $b
Get-ChildItem \\srv2\c$

#but not this
Get-ChildItem \\dom1\c$

#not using this
Get-WSManCredSSP

exit

#Undo
Set-ADComputer -Identity $Server -PrincipalsAllowedToDelegateToAccount $null

#endregion
