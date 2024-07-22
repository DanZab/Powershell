# Uses the AD DNS Debug log to identify the IP addresses of devices targetting that DNS server

# Set this to the DNS Debug Log file
$file = "C:\Temp\DNS2024-07-22T145321Z.log"

<#
Debug Logging on the Server Must be set to:
Packet Direction: Incoming > UDP
Packet contents: Queries/Transfers > Request

Do not use any other options
#>

# Excludes recursive responses
$contents = Get-Content $file | Where-Object {$_ -like "*PACKET *" -and $_ -like "*UDP Rcv*" -and $_ -notlike "*R Q ``[*"}
$IPs = @()

ForEach ($line in $contents) {
    $splits = $line -split ' '
    $IP = $splits | where-object {$_ -match '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'}
    
    If ($IP) {
        Write-Host $line
        Write-Host -ForegroundColor Green $IP
    }
    $IPs += $IP
}

# Removes Duplicates
$IPs = $IPs | Sort-Object -Unique