# Remote Connection (RDP)
Get and/or change the RDP port
```powershell
# To get the RDP port
Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "PortNumber"

# to change the RDP port
$portvalue = 3390
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "PortNumber" -Value $portvalue 
New-NetFirewallRule -DisplayName 'RDPPORTLatest-TCP-In' -Profile 'Public' -Direction Inbound -Action Allow -Protocol TCP -LocalPort $portvalue 
New-NetFirewallRule -DisplayName 'RDPPORTLatest-UDP-In' -Profile 'Public' -Direction Inbound -Action Allow -Protocol UDP -LocalPort $portvalue 
```

# Get Local User Info
```PowerShell
wmic UserAccount

Rename-LocalUser -Name <CURRENT_USERNAME> -NewName <NEW_USERNAME>

# example:
wmic UserAccount WHERE Name='guest' SET Disabled=True	
```
