##CLIENT

if ((gwmi win32_computersystem).partofdomain -eq $true) {

write-host -fore green "Have fun exploiting NoPac!"

$wshell = New-Object -ComObject Wscript.Shell

$wshell.Popup("Your lab is configured, have fun!",0,"Exploit away!",0x1)

} else {

write-host -fore red "Please wait untill we are dont provisioning"

$wshell = New-Object -ComObject Wscript.Shell

$wshell.Popup("Please wait while we configure the lab",0,"Script Running...",0x1)

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

}
