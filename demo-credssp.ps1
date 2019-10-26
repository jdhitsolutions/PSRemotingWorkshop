Return "This is a demo script"

# walk through this on the Windows 10 client
# in the test domain

Enter-PSSession -ComputerName SRV1
Get-ChildItem \\srv2\c$

exit

help Enable-WSManCredSSP -Examples

Invoke-Command { Get-WSManCredSSP } -computer srv1, srv2

Enable-WSManCredSSP Client -DelegateComputer SRV1 -Force

Invoke-command { Enable-WSManCredSSP -Role Server } -computername Srv1
Invoke-Command { Get-WSManCredSSP } -computer srv1

Enter-PSSession -ComputerName srv1 -Authentication Credssp
Enter-PSSession -ComputerName srv1 -Authentication Credssp -Credential company\artd

Get-ChildItem \\srv2\c$

#undo
Disable-WSManCredSSP -Role client
Invoke-Command { Disable-WSManCredSSP -role server } -computer srv1
