
return "This is a walkthrough demo"

Enter-PSSession -VMName srv1 -Credential $artd

$computer = $env:computername #"SRV1"

Get-WSManInstance -resourceuri winrm/config/listener -selectorset @{address = "*"; transport = "http" } -ComputerName $computer

Get-WSManInstance -resourceuri winrm/config/listener -selectorset @{address = "*"; transport = "https" } -ComputerName $computer

#get certificate thumbprint
#how you get the SSL cert installed is up to you
#Jeff - you may need to finish setting up the CA on Dom1

$cred = Get-Credential company\artd
#a hack to pass credentials
net use * \\dom1\c$ /user:company\artd $cred.GetNetworkCredential().Password

$getParams = @{
    template          = 'CompanyServer'
    url               = "ldap:" #'https://dom1.company.pri/ADPolicyProvider_CEP_Kerberos/service.svc/cep'
    CertStoreLocation = 'Cert:\LocalMachine\My\'
    #SubjectName = "CN=Srv1.Company.pri"
    Verbose           = $True
}

Get-Certificate @getparams

$cert = Get-ChildItem cert:\localmachine\my | Where-Object { $_.EnhancedKeyUsageList -match "Server Authentication" } | Select-Object -first 1
$dns = Resolve-DnsName -Name $computer -TcpOnly -Type A

$settings = @{
    Address               = $dns.IPAddress
    Transport             = "https"
    CertificateThumbprint = $cert.Thumbprint
    Enabled               = "True"
    Hostname              = $cert.DnsNameList.unicode
}

New-WSManInstance -resourceuri 'winrm/config/Listener' -selectorset @{Address = "*"; Transport = "HTTPS" } -ValueSet $settings # -ComputerName $computer -Verbose

Get-WSManInstance -resourceuri winrm/config/listener -selectorset @{address = "*"; transport = "https" } #-ComputerName $computer

#YOU MAY ALSO NEED A FIREWALL RULE
exit

#hostname must match certificate name
enter-pssession -ComputerName srv1.company.pri -UseSSL

<#

Remove-WSManInstance -resourceuri winrm/config/listener -selectorset @{address="*";transport="https"} -ComputerName $computer 

#>

# New-WSManInstance winrm/config/Listener -SelectorSet @{Transport=HTTPS} -ValueSet @{Hostname="HOST";CertificateThumbprint="XXXXXXXXXX"}