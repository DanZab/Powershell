<#
    .NOTES
    This is the master list of users/groups that can be members of the local administrators group:
    %COMPUTERNAME%\HelpDesk - Help Desk local admin account
    %COMPUTERNAME%\Administrator - Default local admin on servers

    DOMAIN\Exchange Trusted Subsystem - Exchange required account
    DOMAIN\Organization Management - Exchange required account

    DOMAIN\AllServers-Administrators - Standard Local Admin group
    DOMAIN\SQL-Administrators - Standard Local Admin group
    DOMAIN\Domain Admins - Standard Local Admin group

    DOMAIN\Enterprise Admins - Administrators on Domain Controllers
#>

Function Check-MemberList {
    Param (
        $LAGMembers,
        $hostname,
        [array]$IllegalMember,
        [int]$MemberCount
    )
    foreach($Member in $LAGMembers) { 
        switch ($Member) { 
            #Standard local admin users
            "$($hostname)\HelpDesk" `
            {$MemberCount = $MemberCount + 1; break;}
            "$($hostname)\Administrator" `
            {$MemberCount = $MemberCount + 1; break;}
            
            #Exchange specific groups
            "DOMAIN\Exchange Trusted Subsystem" `
            {$MemberCount = $MemberCount + 1; break;}
            "DOMAIN\Organization Management" `
            {$MemberCount = $MemberCount + 1; break;}
            
            #Standard server administrator groups
            "DOMAIN\AllServers-Administrators" `
            {$MemberCount = $MemberCount + 1; break;}
            "DOMAIN\SQL-Administrators" `
            {$MemberCount = $MemberCount + 1; break;}
            "DOMAIN\Domain Admins" `
            {$MemberCount = $MemberCount + 1; break;}
            
            #Group on Domain Controllers
            "DOMAIN\Enterprise Admins" `
            {$MemberCount = $MemberCount + 1; break;}
            
            default {$IllegalMember += "$Member`n"} 
        } 
    }

    Return $IllegalMember
}