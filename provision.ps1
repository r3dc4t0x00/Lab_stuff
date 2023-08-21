-----DC

Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

Install-ADDSForest -DomainName "nopac.local" -DomainNetBiosName "NOPAC" -InstallDns:$true -NoRebootCompletion:$true

$PASSWORD= ConvertTo-SecureString –AsPlainText -Force -String password123!
New-ADUser -Name "Bobby Tables" -GivenName "Bobby" -Surname "Tables" -SamAccountName "btables" -AccountPassword (Read-Host -AsSecureString "Input User Password") -ChangePasswordAtLogon $False -Company "Cybrary" -Title "CEO" -State "Virginia" -City "Glen Allen" -Description "Bobby Tables Helpdesk user 6" -EmployeeNumber "6" -Department "Help Desk" -DisplayName "Bobby Tables" -Country "us" -PostalCode "23059" -Enabled $True

$PASSWORDDA= ConvertTo-SecureString –AsPlainText -Force -String password123!
New-ADUser -Name "DAdmin" -Description "Domain Admin" -Enabled $true -AccountPassword $PASSWORDDA
Add-ADGroupMember -Identity "Domain Admins" -Member DAdmin

$DNS = (
    Get-NetIPConfiguration |
    Where-Object {
        $_.IPv4DefaultGateway -ne $null -and
        $_.NetAdapter.Status -ne "Disconnected"
    }
).IPv4Address.IPAddress

#get range for scanner

$ip = $DNS
$sep = $ip.lastindexof(".") 
$network = $ip.substring(0,$sep) 
$net = $network + "."

Function Send-StringOverTcp ( 
    [Parameter(Mandatory=$True)][String]$DataToSend,
    [Parameter(Mandatory=$True)][String]$Hostname, 
    [Parameter(Mandatory=$True)][UInt16]$Port)
{
    Try
    {
        $ErrorActionPreference = "Stop"
        $TCPClient  = New-Object Net.Sockets.TcpClient
        $IPEndpoint = New-Object Net.IPEndPoint($([Net.Dns]::GetHostEntry($Hostname)).AddressList[0], $Port)
        $TCPClient.Connect($IPEndpoint)
        $NetStream  = $TCPClient.GetStream()
        [Byte[]]$Buffer = [Text.Encoding]::ASCII.GetBytes($DataToSend)
        $NetStream.Write($Buffer, 0, $Buffer.Length)
        $NetStream.Flush()
    }
    Finally
    {
        If ($NetStream) { $NetStream.Dispose() }
        If ($TCPClient) { $TCPClient.Dispose() }
    }
}


#send string to all hosts to trigger join
$list = 1..255 -replace '^',$net
Send-StringOverTcp -DataToSend $DNS -Hostname $list -Port 2050

sleep 30

Restart-Computer

------------CLIENT

#listen for DC for DNS

$port=2050
$IPEndPoint=New-Object System.Net.IPEndPoint([IPAddress]::Any,$port)
$TcpListener=New-Object System.Net.Sockets.TcpListener $IPEndPoint
$TcpListener.Start()
 
$AcceptTcpClient=$TcpListener.AcceptTcpClient()
$GetStream=$AcceptTcpClient.GetStream()
$StreamReader=New-Object System.IO.StreamReader $GetStream
$DNS = $StreamReader.ReadLine()

$StreamReader.Dispose()
$GetStream.Dispose()
$AcceptTcpClient.Dispose()
$TcpListener.Stop()

#domain join

$username = "NOPAC\DAdmin"
$password = 'password123!' | ConvertTo-SecureString
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password

Set-DnsClientServerAddress -InterfaceIndex 9 -ServerAddresses ($DNS,$DNS)

add-computer –domainname nopac.local -Credential $cred -restart –force
