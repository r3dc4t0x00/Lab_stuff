##DC

if ((gwmi win32_computersystem).partofdomain -eq $true) {

write-host -fore green "Have fun exploiting NoPac!"

$wshell = New-Object -ComObject Wscript.Shell

$wshell.Popup("Install Complete",0,"Done",0x1)

} else {

write-host -fore red "Please wait untill we are dont provisioning"

$wshell = New-Object -ComObject Wscript.Shell

$wshell.Popup("Please wait while we configure the lab",0,"Script Running...",0x1)

#Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

$setupcred= ConvertTo-SecureString –AsPlainText -Force -String #
Install-ADDSForest -DomainName "nopac.local" -DomainNetBiosName "NOPAC" -InstallDns -SafeModeAdministratorPassword $setupcred -NoRebootOnCompletion -Confirm:$false

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

}
