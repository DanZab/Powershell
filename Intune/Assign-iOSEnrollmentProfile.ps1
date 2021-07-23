<#
.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

Original script (Assign-ProfileToDevice) can be found at:
https://github.com/microsoftgraph/powershell-intune-samples/tree/master/AppleEnrollment

Modified 07-2021 by Dan Zabinski https://github.com/DanZab

.SYNOPSIS
    Can be used to retrieve a list of Intune iOS Enrollment Tokens and Profiles, bulk
    assign profiles to devices, or assign profiles individually


.DESCRIPTION
    This script will prompt you to perform one of three actions
    1. List Tokens and Profiles

    2. Bulk assign profiles
       This will require a CSV input file to assign them

    3. Assign profiles individually

    It may be helpful to do option 3 first as a test.
#>

####################################################

function Get-AuthToken {

<#
.SYNOPSIS
This function is used to authenticate with the Graph API REST interface
.DESCRIPTION
The function authenticate with the Graph API Interface with the tenant name
.EXAMPLE
Get-AuthToken
Authenticates you with the Graph API interface
.NOTES
NAME: Get-AuthToken
#>

[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    $User
)

$userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User

$tenant = $userUpn.Host

Write-Host "Checking for AzureAD module..."
Write-Host

    $AadModule = Get-Module -Name "AzureAD" -ListAvailable

    if ($AadModule -eq $null) {

        Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
        $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable

    }

    if ($AadModule -eq $null) {
        write-host
        write-host "AzureAD Powershell module not installed..." -f Red
        write-host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
        write-host "Script can't continue..." -f Red
        write-host
        exit
    }

# Getting path to ActiveDirectory Assemblies
# If the module count is greater than 1 find the latest version

    if($AadModule.count -gt 1){

        $Latest_Version = ($AadModule | select version | Sort-Object)[-1]

        $aadModule = $AadModule | ? { $_.version -eq $Latest_Version.version }

            # Checking if there are multiple versions of the same module found

            if($AadModule.count -gt 1){

            $aadModule = $AadModule | select -Unique

            }

        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

    }

    else {

        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

    }

[System.Reflection.Assembly]::LoadFrom($adal) | Out-Null

[System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null

$clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"

$redirectUri = "urn:ietf:wg:oauth:2.0:oob"

$resourceAppIdURI = "https://graph.microsoft.com"

$authority = "https://login.microsoftonline.com/$Tenant"

    try {

    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

    # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
    # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession

    $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"

    $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")

    $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$clientId,$redirectUri,$platformParameters,$userId).Result

        # If the accesstoken is valid then create the authentication header

        if($authResult.AccessToken){

        # Creating header for Authorization token

        $authHeader = @{
            'Content-Type'='application/json'
            'Authorization'="Bearer " + $authResult.AccessToken
            'ExpiresOn'=$authResult.ExpiresOn
            }

        return $authHeader

        }

        else {

        Write-Host
        Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
        Write-Host
        break

        }

    }

    catch {

    write-host $_.Exception.Message -f Red
    write-host $_.Exception.ItemName -f Red
    write-host
    break

    }

}

####################################################

Function Test-JSON(){

<#
.SYNOPSIS
This function is used to test if the JSON passed to a REST Post request is valid
.DESCRIPTION
The function tests if the JSON passed to the REST Post is valid
.EXAMPLE
Test-JSON -JSON $JSON
Test if the JSON is valid before calling the Graph REST interface
.NOTES
NAME: Test-JSON
#>

param (

$JSON

)

    try {

    $TestJSON = ConvertFrom-Json $JSON -ErrorAction Stop
    $validJson = $true

    }

    catch {

    $validJson = $false
    $_.Exception

    }

    if (!$validJson){

    Write-Host "Provided JSON isn't in valid JSON format" -f Red
    break

    }

}

####################################################

Function Get-DEPOnboardingSettings {

<#
.SYNOPSIS
This function retrieves the DEP onboarding settings for your tenant. DEP Onboarding settings contain information such as Token ID, which is used to sync DEP and VPP
.DESCRIPTION
The function connects to the Graph API Interface and gets a retrieves the DEP onboarding settings.
.EXAMPLE
Get-DEPOnboardingSettings
Gets all DEP Onboarding Settings for each DEP token present in the tenant
.NOTES
NAME: Get-DEPOnboardingSettings
#>
    
[cmdletbinding()]
    
Param(
[parameter(Mandatory=$false)]
[string]$tokenid
)
    
    $graphApiVersion = "beta"
    
        try {
    
                if ($tokenid){
                
                $Resource = "deviceManagement/depOnboardingSettings/$tokenid/"
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
                (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get)
                     
                }
    
                else {
                
                $Resource = "deviceManagement/depOnboardingSettings/"
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
                (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get).value
                
                }
                   
            }
        
        catch {
    
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break
    
        }
    
    } 

####################################################

Function Get-DEPProfiles(){

<#
.SYNOPSIS
This function is used to get a list of DEP profiles by DEP Token
.DESCRIPTION
The function connects to the Graph API Interface and gets a list of DEP profiles based on DEP token
.EXAMPLE
Get-DEPProfiles
Gets all DEP profiles
.NOTES
NAME: Get-DEPProfiles
#>

[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    $id
)

$graphApiVersion = "beta"
$Resource = "deviceManagement/depOnboardingSettings/$id/enrollmentProfiles"

    try {

        $SyncURI = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
        Invoke-RestMethod -Uri $SyncURI -Headers $authToken -Method GET

    }

    catch {

    Write-Host
    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}

####################################################

Function Assign-ProfileToDevice(){

####################################################

[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    $id,
    [Parameter(Mandatory=$true)]
    $DeviceSerialNumber,
    [Parameter(Mandatory=$true)]
    $ProfileId
)

$graphApiVersion = "beta"
$Resource = "deviceManagement/depOnboardingSettings/$id/enrollmentProfiles('$ProfileId')/updateDeviceProfileAssignment"

    try {

        $DevicesArray = $DeviceSerialNumber -split ","

        $JSON = @{ "deviceIds" = $DevicesArray } | ConvertTo-Json

        Test-JSON -JSON $JSON

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"

        Write-Host "Success: " -f Green -NoNewline
        Write-Host "Device assigned!"
        Write-Host

        $AssignedProfileStatus = "Success"

    }

    catch {

        Write-Host
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        
        $AssignedProfileStatus = "Failed"
    }

    Return $AssignedProfileStatus

}

####################################################

Function Get-IntuneDevice ($IntuneDeviceSerial) {
    $DeviceSerialNumber = $IntuneDeviceSerial

    # If variable contains spaces, remove them
    $DeviceSerialNumber = $DeviceSerialNumber.replace(" ","")

    If(!($DeviceSerialNumber)){
    
        $IntuneDeviceResult = "No Serial Number entered"
    }
    Else {
        $graphApiVersion = "beta"
        $Resource = "deviceManagement/depOnboardingSettings/$($id)/importedAppleDeviceIdentities?`$filter=discoverySource eq 'deviceEnrollmentProgram' and contains(serialNumber,'$DeviceSerialNumber')"

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        $SearchResult = (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get).value

        If (!($SearchResult)){
    
            $IntuneDeviceResult = "Device Not Found"
            Write-Host -ForegroundColor Yellow "$IntuneDeviceResult"

        } Else {
    
            $IntuneDeviceResult = "Device Found"

        }
    }

    Return $IntuneDeviceResult
}

Function Get-TokensAndProfiles($TokenList) {
    $FinalList =@()

    ForEach ($token in $TokenList) {
        $TokenId = $token.id
        $TokenName = $token.TokenName

        $Profiles = (Get-DEPProfiles -id $TokenId).value

        ForEach ($Profile in $Profiles) {
            $ProfileName = $Profile.DisplayName
            $ProfileId = $Profile | Select-Object -ExpandProperty id

            $Object = New-Object PSObject -Property @{
                TokenName = $TokenName
                TokenId = $TokenId
                ProfileName = $ProfileName
                ProfileId = $ProfileId
            }

            $FinalList += $Object
        }
    }

    $FinalList | Select TokenName, ProfileName | Sort ProfileName | Format-Table

    Write-Host "Would you like to create a CSV Input template? (" -NoNewline
    Write-Host -ForegroundColor Green "[Enter]" -NoNewline
    Write-Host " / " -NoNewline
    Write-Host -ForegroundColor Green "Y " -NoNewline
    Write-Host "for Yes, " -NoNewline
    Write-Host -ForegroundColor Red "N " -NoNewline
    Write-Host "for No) " -NoNewline

    $Prompt = Read-Host

    If ($Prompt -eq "" -or $Prompt -eq "y") {
        $SampleCSV = @()
        For ($i=1;$i -le $FinalList.count; $i++) {
            if ($i -lt 10) {
                $SampleSerialNumber = "X00XX00XXXX$i"
            } elseif ($i -ge 10 -and $i -lt 100) {
                $SampleSerialNumber = "X00XX$iXXXX1"
            } elseif ($i -ge 100) {
                $SampleSerialNumber = "X$iX00XXXX1"
            }

            $SampleObject = New-Object PSObject -Property @{
                DeviceSerialNumber = $SampleSerialNumber
                Token = $FinalList[$i -1].TokenName
                Profile = $FinalList[$i -1].ProfileName
            }

            $SampleCSV += $SampleObject
        }

        $SampleCSV = $SampleCSV | Select DeviceSerialNumber, Token, Profile

        Save-Output -FileName "$(Get-Date -Format yyyy-MM_HHmm)_IntuneProfileSample.csv" -DataOutput $SampleCSV
    }
}

Function Get-InputFile(){
    $InputFolderPath = "$((Get-Location).Path)\input"
    Try {
        $FileList = Get-ChildItem $InputFolderPath
    }
    Catch {
        Write-Host -ForegroundColor Red "Input folder not found at " -NoNewline
        Write-Host -ForegroundColor Yellow $InputFolderPath

        $FileList = "None"
    }

    Do {
        If ($FileList -ne "none") {
            Write-Host "Pleaes choose your input file: "
            For ($i=0; $i -le ($FileList.Count - 1); $I++){
                Write-Host -BackgroundColor White " " -NoNewline
                Write-Host -ForegroundColor Black -BackgroundColor White ($i + 1) -NoNewline
                Write-Host -BackgroundColor White " " -NoNewline
                Write-Host " " -NoNewline
                Write-Host $FileList[$i]
            }
            Write-Host -ForegroundColor Black -BackgroundColor White " F " -NoNewline
            Write-Host " to enter custom file path"
            
            Write-Host -ForegroundColor Black -BackgroundColor White " X " -NoNewline
            Write-Host " or " -NoNewline
            Write-Host -ForegroundColor Black -BackgroundColor White " Exit " -NoNewline
            Write-Host " to cancel"
            Write-Host `n

            $UserInput = Read-Host "Please enter your selection"
        }
        Else {
            $UserInput = "F"
        }
        
        Switch -Regex ($UserInput) {
            '\d+' {
                [int]$Selection = $UserInput
                $Selection = $Selection - 1
                $InputFile = "$($InputFolderPath)\$($FileList[$Selection].Name)"

                If ($Status) {Clear-Variable Status}
            }
            "F" {
                Write-Host "Please enter the full file path for the input file (type " -NoNewline
                Write-Host -ForegroundColor Yellow "X" -NoNewline
                Write-Host " or " -NoNewline
                Write-Host -ForegroundColor Yellow "Exit" -NoNewline
                Write-Host " to cancel): " -NoNewline
                $CustomFilePath = Read-Host

                Switch ($CustomFilePath) {
                    "Exit" {Write-Host "Cancelling script"; Exit}
                    "X" {Write-Host "Cancelling script"; Exit}
                    default {
                        if (Test-Path $CustomFilePath) {
                            $InputFile = $CustomFilePath
                            Clear-Variable error
                        }
                        else {
                            Write-Host -ForegroundColor Red "Invalid File Path"
                            $Status = "error"
                        }
                            ; Break}
                }
            }
            "Exit" {Write-Host "Cancelling script"; Exit}
            "X" {Write-Host "Cancelling script"; Exit}
            default {$Status = "error"; break}
        }
        
    } While ($Status)

    return $InputFile
}

Function Save-Output ($FileName, $DataOutput) {
    $CurrentFolderPath = "$((Get-Location).Path)"
    $OutputPath = "$CurrentFolderPath\$FileName"

    $DataOutput | Export-CSV $OutputPath -NoTypeInformation

    Write-Host "Output saved to:"
    Write-Host -ForegroundColor Yellow "$OutputPath"

    Set-Clipboard -Value $OutputPath
}

####################################################

#region Authentication

cls 

write-host

# Checking if authToken exists before running authentication
if($global:authToken){

    # Setting DateTime to Universal time to work in all timezones
    $DateTime = (Get-Date).ToUniversalTime()

    # If the authToken exists checking when it expires
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

        if($TokenExpires -le 0){

        write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        write-host

            # Defining User Principal Name if not present

            if($User -eq $null -or $User -eq ""){

            $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
            Write-Host

            }

        $global:authToken = Get-AuthToken -User $User

        }
}

# Authentication doesn't exist, calling Get-AuthToken function

else {

    if($User -eq $null -or $User -eq ""){

    $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
    Write-Host

    }

# Getting the authorization token
 $global:authToken = Get-AuthToken -User $User

}

#endregion

####################################################
$Options = @("List all Tokens and Profiles",`
    "Assign profiles to multiple devices (requires a csv input)",`
    "Assign a profile to a single device")

Write-Host "Choose what you would like to do:"
for ($i=1;$i -le $Options.count; $i++) {
    Write-Host "$i. $($Options[$i-1])"
}
Write-Host 
[int]$ScriptPrompt = Read-Host "Enter the value for the option you would like "

#region DEP Tokens

$tokens = (Get-DEPOnboardingSettings)

if($tokens){
    Switch ($ScriptPrompt) {
        default {Write-Host -ForegroundColor Yellow "No value selected"}
        1 {
            Get-TokensAndProfiles $tokens
        }
        2 {
            Write-Host `n
            Write-Host "Select a CSV input file. If you do not have one, use the 'List all Tokens and Profiles' function to generate a sample."
            Write-Host

            $InputCSV = Get-InputFile

            $DeviceList = Import-CSV $InputCSV

            $FinalList = @()

            ForEach ($Device in $DeviceList) {
                If ($null -eq $id) {
                    $AssignedTokenName = $Device.Token
                    $SelectedToken = $tokens | Where-Object { $_.TokenName -eq "$AssignedTokenName" }
                    $id = $SelectedToken | Select-Object -ExpandProperty id
                }

                Write-Host "Assigning $($Device.DeviceSerialNumber) to $($Device.Token) $($Device.Profile)"
                $DeviceSerial = $Device.DeviceSerialNumber
                $DeviceCheck = Get-IntuneDevice $DeviceSerial

                If ($DeviceCheck -eq "Device Found") {
                    $AssignedTokenName = $Device.Token
                    $AssignedProfileName = $Device.Profile

                    $SelectedToken = $tokens | Where-Object { $_.TokenName -eq "$AssignedTokenName" }
                    $SelectedTokenId = $SelectedToken | Select-Object -ExpandProperty id

                    $Profiles = (Get-DEPProfiles -id $id).value
                    $SelectedProfile = $Profiles | Where-Object { $_.DisplayName -eq "$AssignedProfileName" }
                    $SelectedProfileId = $SelectedProfile | Select-Object -ExpandProperty id

                    $ProfileStatus = Assign-ProfileToDevice -id $SelectedTokenId -DeviceSerialNumber $DeviceSerial -ProfileId $SelectedProfileId

                    If ($ProfileStatus -eq "Success") {
                        $DeviceStatus = "Assigned to profile $AssignedProfileName"
                    } Else {
                        $DeviceStatus = "Failed to assign profile"
                    }
                }
                Else {
                    $DeviceStatus = "Not Found"
                }

                $Object = New-Object PSObject -Property @{
                    DeviceSerial = $DeviceSerial
                    Status = $DeviceStatus
                }

                $FinalList += $Object
            }

            $FinalList = $FinalList | Select DeviceSerial, Status
            
            Save-Output -FileName "$(Get-Date -Format yyyy-MM_HHmm)_IntuneProfileAssignments.csv" -DataOutput $FinalList
        }
        3 {
                
                $DeviceSerialNumberPrompt = Read-Host "Please enter device serial number"
                Get-IntuneDevice $DeviceSerialNumberPrompt

                $tokencount = @($tokens).count

                if ($tokencount -gt 1){

                write-host "Listing DEP tokens..." -ForegroundColor Yellow
                Write-Host
                $DEP_Tokens = $tokens.tokenName | Sort-Object -Unique

                $menu = @{}

                for ($i=1;$i -le $DEP_Tokens.count; $i++) 
                { Write-Host "$i. $($DEP_Tokens[$i-1])" 
                $menu.Add($i,($DEP_Tokens[$i-1]))}

                Write-Host
                [int]$ans = Read-Host 'Select the token you wish you to use (numerical value)'
                $selection = $menu.Item($ans)
                Write-Host

                    if ($selection){

                    $SelectedToken = $tokens | Where-Object { $_.TokenName -eq "$Selection" }

                    $SelectedTokenId = $SelectedToken | Select-Object -ExpandProperty id
                    $id = $SelectedTokenId

                    }

                }

                elseif ($tokencount -eq 1) {

                    $id = (Get-DEPOnboardingSettings).id
    
                }

                ####################################################

                # Device lookup region

                ####################################################

                $Profiles = (Get-DEPProfiles -id $id).value

                if($Profiles){
                
                Write-Host
                Write-Host "Listing DEP Profiles..." -ForegroundColor Yellow
                Write-Host

                $enrollmentProfiles = $Profiles.displayname | Sort-Object -Unique

                $menu = @{}

                for ($i=1;$i -le $enrollmentProfiles.count; $i++) 
                { Write-Host "$i. $($enrollmentProfiles[$i-1])" 
                $menu.Add($i,($enrollmentProfiles[$i-1]))}

                Write-Host
                $ans = Read-Host 'Select the profile you wish to assign (numerical value)'

                    # Checking if read-host of DEP Profile is an integer
                    if(($ans -match "^[\d\.]+$") -eq $true){

                        $selection = $menu.Item([int]$ans)

                    }

                    if ($selection){
   
                        $SelectedProfile = $Profiles | Where-Object { $_.DisplayName -eq "$Selection" }
                        $SelectedProfileId = $SelectedProfile | Select-Object -ExpandProperty id
                        $ProfileID = $SelectedProfileId

                    }

                    else {

                        Write-Host
                        Write-Warning "DEP Profile selection invalid. Exiting..."
                        Write-Host
                        break

                    }

                }

                else {
    
                    Write-Host
                    Write-Warning "No DEP profiles found!"
                    break

                }

                ####################################################

                $Status = Assign-ProfileToDevice -id $id -DeviceSerialNumber $DeviceSerialNumber -ProfileId $ProfileID

                Write-Host
                Read-Host "Press Enter to finish"
                Exit
        }

    }
    # End of Switch Statement

} Else {
    
    Write-Warning "No DEP tokens found!"
    Write-Host
    break

}
