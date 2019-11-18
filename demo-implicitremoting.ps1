#demo implicit remoting

#create a PowerShell session to a remote computer
$s = New-PSSession -ComputerName DOM1

#import the module you want
Invoke-Command -scriptblock {import-module ActiveDirectory} -Session $s

#export the session
#this only needs to be done once
help Export-PSSession

#only export these commands
$commands = "Get-ADUSer","Get-ADGroup","Get-ADGroupMember","Get-ADComputer"
Export-PSSession -Session $s -OutputModule myAD -Module ActiveDirectory -Force -CommandName $commands
#remove the session

Remove-PSSession $s

#I now have a new module
get-module myAD -ListAvailable

#import it
import-module myAD

Get-Command -Module myAD

get-aduser maryl

#new session created
get-pssession

get-adgroupmember "IT" | Select Name,DistinguishedName -first 10

#remove module
remove-module myAD

#import again but use a prefix to avoid naming conflicts
import-module myAD -Prefix rem
Get-Command -Module myAD

$c = get-remADComputer srv1

#done via a remoting session
$c
$c | Get-Member

remove-module myAD
#removes PSSession
get-pssession

#look at module
ise (get-module myAD -ListAvailable).path


