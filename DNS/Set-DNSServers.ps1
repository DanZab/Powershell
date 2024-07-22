#Need to specify input file for $ComputerList


$ComputerList = Get-Content "C:\Temp\ServerList.txt" 
# What to set the new DNS servers to
$DnsServers =@("10.15.1.20","10.15.1.21") 
 
ForEach ($ComputerName in $ComputerList) { 

	#Ping to test for connectivity to the computer object
    $Result =  Get-WmiObject win32_pingstatus -Filter "address='$ComputerName'" 
	
    if ($Result.StatusCode -eq 0) {
	
		#This searches for each network adapter where the type is Ethernet, can be modified to isolate other adapters
        $RemoteNics = Get-WmiObject -class win32_networkadapter -Computer $ComputerName | Where-Object {$_.AdapterType -like "ethernet*"}
		
		
		#This loop is here in case there are multiple network adapters
		ForEach ($RemoteNic in $RemoteNics) { 
		
			$NicIndex = $RemoteNic.index
			$NicName = $RemoteNic.name
			$DnsServerList = $(Get-WmiObject win32_networkadapterconfiguration -Computer $ComputerName -Filter 'IPEnabled=true' | Where-Object {$_.index -eq $NicIndex}).dnsserversearchorder 
			
			
			#This variable is available if you need to reference the current primary DNS server
			#$PrimaryDnsServer = $DnsServerList | Select-Object -First 1 
			
			if ($DnsServerList -ne $null) {
			
				Write-Host "Changing DNS server IPs on $ComputerName" -b "Yellow" -ForegroundColor "black"
				Write-Host "Interface Name $NicName" -b "Yellow" -ForegroundColor "black"
				Write-Host "Old servers - $DnsServerList" -b "Yellow" -ForegroundColor "black"
				
				$Change = Get-WmiObject win32_networkadapterconfiguration -Computer $ComputerName | Where-Object {$_.index -eq $NicIndex} 
				$Change.SetDnsServerSearchOrder($DnsServers) | Out-Null
				
				$Changes = $(Get-WmiObject win32_networkadapterconfiguration -Computer $ComputerName -Filter 'IPEnabled=true' | Where-Object {$_.index -eq $NicIndex}).dnsserversearchorder 
				Write-Host "$ComputerName's servers have been updated to $Changes" -ForegroundColor "Green"
				
			}
			Else {
				Write-Host "No DNS Servers on Nic Interface $NicName" -ForegroundColor "Yellow"
			}
		}
    } 
    Else {
        Write-Host "$ComputerName is down, cannot change IP address" -b "Red" -ForegroundColor "white" 
    } 
}