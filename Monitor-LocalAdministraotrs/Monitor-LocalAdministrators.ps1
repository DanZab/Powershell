<#
    .SYNOPSIS
        Runs as a scheduled task, triggered on the Security Event ID 4732 which occurs
        when a user adds someone to a local group on a device.

        Emails an alert to specified target with a message including the client name and
        users that were added.

    .DESCRIPTION
        This script needs to be placed in a network share accessible to all domain computers.
        A Scheduled Task should then be configured via Group Policy that calls this script
        when Security Event ID 4732 is generated on client computers.
            
        The template for that task is included in the Repo https://github.com/DanZab/Powershell.

        That task runs the script along with the group that was modified and the user that was
        added/removed as parameters.

		If the local group was "Administrators", then this script does the following:
        1. Gets the list of users from the local Administrators group on the device
        2. Checks whether each user on the list is an approved administrator
        3. Sends an SMTP message alert that includes the name of the device along
            with the non-approved users in the Administrators group.
			
        Includes a reference to the Check-MemberList.ps1 file which contains the approved
        administrators list. These files are kept separate so Check-MemberList can be called
        separately by an SCCM Configuration Baseline as well.

    .NOTES 
        Edited: Dan Zabinski 7/18/2020     
            
        Original Reference:
        https://www.petervanderwoude.nl/post/verify-local-administrators-via-powershell-and-compliance-settings-in-configmgr-2012/

#>

param(
# This parameter is the name of the group being modified from the Event Description.
[string]$TargetUserName,
[string]$SubjectUserName
)

# Include master member list, cannot be a relative path
. '\\domain.local\NETLOGON\Scripts\Monitor-LocalAdministrators\Check-MemberList.ps1'


# Important to remember that this script runs in the context of the client system where the event is triggered.
If ($TargetUserName -eq "Administrators") {
    #$MemberCount = 0
    $IllegalMember = ""
    $hostname = $env:COMPUTERNAME

    $LocAdmGroupMembers = (Get-WmiObject -Query "Associators of {Win32_Group.Domain='$hostname',Name='Administrators'} where Role=GroupComponent").Caption

    $IllegalMember = Check-MemberList -LAGMembers $LocAdmGroupMembers -hostname $hostname

    if ($IllegalMember.length -eq 0) { 
        $Compliance = "Compliant" 
    } 
	elseif ($SubjectUserName -like "*$") { 
        $Compliance = "Compliant" 
    } 
    else { 
        $SmtpServer = "smtp.domain.local"
        $MessageFrom = "Local Admin Alert <DoNotReply@domain.com>"
        $MessageTo = "Dan Zabinski <AdminAlerts@domain.com>"
        $MessageSubject = "ALERT: Local Administrator added to $hostname"
        $MessageBody = "$SubjectUserName has added a user or group to the local administrators group on $hostname. `n The following users are non-standard local admins on that device: `n $IllegalMember"
		$Date = Get-Date -UFormat "%m/%d/%Y %R"
		
        Send-MailMessage -SmtpServer $SmtpServer -From $MessageFrom -To $MessageTo -Subject $MessageSubject -Body $MessageBody
		
		[string]$ConvertToString = (($IllegalMember -join ", ") -replace "`n","")
		$LogObject = New-Object PSObject -Property @{
			Date = $Date
			User = $SubjectUserName
			Server = $hostname
			LocalAdmins = $ConvertToString
			}
			
		$LogObject | Select Date, User, Server, LocalAdmins | Export-CSV -Append "\\domain.local\NETLOGON\Scripts\Monitor-LocalAdministrators\Logs\Monitor-LocalAdministrators.csv" -NoTypeInformation
	}
}