<#
    .DESCRIPTION
        This is a collection of useful components I've accumulated over time that I
        incorporate into other scripts or daily use.

        It includes the following elements:

        1. Write Status
           I use this function on larger scripts to easily format status messages I want
           displayed in the console. Replaces 'Write-Host' with 'Write-Status'.

        2. Input file prompt
           Displays each file from an 'input' subdirectory from where the script runs.
           Allows user to easily select the input file they want.

        3. Quick Input
            This is a script template I frequently have open in the ISE console. It
            allows you to quickly enter a list of objects, separated by lines, that are
            then turned into an array you can iterate on.

            This saves the trouble of having to create an input file to run an action
            on a list of objects.

        4. Write-Progress Example
            I use the Write-Progress command frequently to display a progress bar on the
            script I'm running. I like to keep this example handy to copy/paste into
            scripts rather than look it up each time.

    .NOTES 
        Author: Dan Zabinski https://github.com/DanZab
        Date: 8/30/2020

#>

#####################################################################################
#   Fn Write-Status
#####################################################################################
Function Write-Status ($Message){
    Write-Host `n -NoNewline
    Write-Host -ForegroundColor Black -BackgroundColor White "   $Message   "
}

<#
#####################################################################################
#   Fn Get-InputFile
#####################################################################################

    Returns a value containing the path to the selected Input file.

    Can update $InputFolderPath if necessary, by default it uses the input subdirectory
    from the location the script is ran from.

    Example of use (if input file was in CSV form):
        $InputFile = Get-InputFile
        $MyInputArray = Import-CSV $InputFile
#>

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
                    "Exit" {Write-Status "Cancelling script"; Exit}
                    "X" {Write-Status "Cancelling script"; Exit}
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
            "Exit" {Write-Status "Cancelling script"; Exit}
            "X" {Write-Status "Cancelling script"; Exit}
            default {$Status = "error"; break}
        }
        
    } While ($Status)

    return $InputFile
}

#####################################################################################
# Quick Input
#####################################################################################
# Copy/paste your list of objects into the $input variable, then
# update your ForEach loop with the action you would like to perform.

$input = @'
DeviceOne
DeviceTwo
DeviceThree
'@

$MyArray = $input -split "`r`n"
ForEach ($Object in $MyArray) {
    Get-ADComputer $Object
}


#####################################################################################
# Write-Progress Example
#####################################################################################

Write-Host "`n `n `n `n `n"
Write-Host "Performing the specified task"
#Get list of objects to perform the action on
$ObjectList = Import-CSV C:\Temp\Sample.csv

Write-Host "Found $($ObjectList.Count) Objects, performing action"

$i = 1
ForEach ($Object in $ObjectList) {
    Write-Progress -Activity "Object $i out of $($ObjectList.Count)" -PercentComplete ($i / $($ObjectList.Count) * 100)

    #Action

    $i ++
}