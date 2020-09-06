<#
    .SYNOPSIS
        Creates AD Security Groups and adds users

    .DESCRIPTION
        Requires Active Directory PS Modules

        This script does the following:
        1. Prompts for Group Name, Description, Owner and Location
        2. After confirmation, creates the group
        3. Prompts for users to add to the group once it's created
        4. Copies a note to the clipboard to paste into ticket close notes

        The Group Owner, and Task Number (for ticketing system) are added to the group
        notes section after the group has been created.

    .NOTES 
        Author: Dan Zabinski https://github.com/DanZab
        Date: 8/30/2020

#>

Clear-Host

# Generates the menu for selecting group location, stored in a function to be easily updated
Function Show-PathMenu {
    Write-Host "`n"
    Write-Host -ForegroundColor Green "=== Available Security Group OUs ==="

    #  OU=Applications,OU=Groups,DC=domain,DC=local
    Write-Host -ForegroundColor Green "   1: Groups \ Applications"

    #  OU=App1,OU=Applications,OU=Groups,DC=domain,DC=local
    Write-Host -ForegroundColor Green "   2: Groups \ Applications \ App1"

    #  OU=App2,OU=Applications,OU=Groups,DC=domain,DC=local
    Write-Host -ForegroundColor Green "   3: Groups \ Applications \ App2"

    #  OU=Group Policy,OU=Groups,DC=domain,DC=local
    Write-Host -ForegroundColor Green "   4: Groups \ Group Policy"

    Write-Host "`n"
}

####################################################################
# Step 1 - Prompts for Group Name, Description, Owner and Location 
####################################################################

Write-host "Please enter the task or request number: " -ForegroundColor Yellow -NoNewLine
$TaskNumber = Read-host

Write-host "What is the name of the group: " -ForegroundColor Yellow -NoNewLine
$GroupName = Read-Host

Write-host "What is the group description (ex. Grants access to...): " -ForegroundColor Yellow -NoNewLine
$description = Read-Host

Write-host "Who is the group owner: " -ForegroundColor Yellow -NoNewLine
$owner = Read-Host

$Notes = "Owner $owner, $TaskNumber"

Show-PathMenu
Write-host "Please enter the number for the OU where you would like to create the group: " -ForegroundColor Yellow -NoNewLine
$selection = Read-Host
switch ($selection)
{
    '1' 
    { $path = "OU=Applications,OU=Groups,DC=domain,DC=local"}
    '2'
    { $path = "OU=App1,OU=Applications,OU=Groups,DC=domain,DC=local" }
    '3'
    { $path = "OU=App2,OU=Applications,OU=Groups,DC=domain,DC=local" }
    '4'
    { $path = "OU=Group Policy,OU=Groups,DC=domain,DC=local" }
    default
    { Write-host -ForegroundColor Red "No option select, exiting script."; Exit}
}

####################################################################
# Step 2 - After confirmation, creates the group
# Displays the information and the powershell command used to create the group
####################################################################

Write-host "`n"
Write-host "Group Name:" -ForegroundColor Yellow -NoNewLine
Write-host " $GroupName"
Write-host "Group Description:" -ForegroundColor Yellow -NoNewLine
Write-host " $description"
Write-host "Group Notes: " -ForegroundColor Yellow -NoNewLine
Write-host "$Notes"
Write-host "Group Location:" -ForegroundColor Yellow -NoNewLine
Write-host " $path"
Write-host "`n"

Write-host "Is this information correct? Enter " -ForegroundColor Yellow -NoNewLine
Write-host "Y" -ForegroundColor Green -NoNewLine
Write-host " to coninue: " -ForegroundColor Yellow -NoNewLine
$continue = Read-Host

If ($continue -eq "Y") {

Write-host "`n"
Write-Host -ForegroundColor Yellow "New-ADGroup -Name ""$GroupName"" -SamAccountName ""$GroupName"" -GroupCategory Security -GroupScope Global -DisplayName ""$GroupName"" -Path ""$path"" -Description ""$description"" -OtherAttributes @{'info'=""$Notes""}"


Try {
    New-ADGroup -Name "$GroupName" -SamAccountName "$GroupName" -GroupCategory Security -GroupScope Global -DisplayName "$GroupName" -Path "$path" -Description "$description" -OtherAttributes @{'info'="$Notes"}

    Write-host "`n"
    Write-Host -ForegroundColor Green "New Group Created."


    $skip = 0
    }
Catch {
    Write-Host -ForegroundColor Red "Failed to create group."
    Write-Host -ForegroundColor Red "$($_.Exception.Message)"

    $skip = 1
    }

    Write-host "`n"

####################################################################
# Step 3 - Prompts for users to add to the group once it's created
####################################################################
    if ($skip -eq 0) {

        # Begin Section to add users to the new Security Group
        $userCount = 0

        Write-host "Enter user(s) to add to group. (" -ForegroundColor Yellow -NoNewLine
        Write-host "X" -ForegroundColor Green -NoNewLine
        Write-host " or " -ForegroundColor Yellow -NoNewLine
        Write-host "[Blank]" -ForegroundColor Green -NoNewLine
        Write-host " to end.) " -ForegroundColor Yellow

        Do {
            Write-host "User $($userCount + 1): " -ForegroundColor Yellow -NoNewLine
            # Prompt for usernames, remove tabs and spaces
            $user = Read-Host
            $user = $user.Trim("`t"," ")
                
            If (($user -ne "X") -and ($user -ne "")) {
                Try {
                    $ADUser = Get-ADUser $user
                    Add-ADGroupMember $GroupName -Members $ADUser.name

                    $userCount = $userCount + 1
                }
                Catch {
                    Write-Host -ForegroundColor Red "User not found."
                    Write-Host -ForegroundColor Red "$($_.Exception.Message)"
                }
            }

        } While (($user -ne "X") -and ($user -ne ""))
        
        if ($userCount -gt 0) {
            Write-host "`n"
            Write-host "The following users are members of the new $GroupName group:" -ForegroundColor Green
            Get-ADGroupMember $GroupName | Select Name | Format-Table -AutoSize
            
            if ($userCount -eq 1) {
                $EndStatement = ", $user added."
            } else {
                $EndStatement = ", users added."
            }
        } else {
            $EndStatement = "."
        }

####################################################################
# Step 4 - Copies a note to the clipboard to paste into ticket close notes
####################################################################
        $Statement = "Group $GroupName created" + $EndStatement
        Write-Host -ForegroundColor Green "Saved to clipboard: " -NoNewline
        Write-Host $Statement
        Set-Clipboard -Value $Statement

        Write-host "`n"
    }
    
} Else {

Write-host -ForegroundColor Red "Action cancelled, no group was created"

}