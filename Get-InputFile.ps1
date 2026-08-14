#####################################################################################
#   Fn Get-InputFile
#####################################################################################
<#
    Dynamically generates a list of available input files to select from.
    Returns a value containing the path to the selected Input file.
    Can update $InputFolderPath if necessary, by default it uses the input 
    subdirectory from the location the script is ran from.
    Example of use (if input file was in CSV form):
        $InputFile = Get-InputFile
        $MyInputArray = Import-CSV $InputFile

    Parameters:
    Directory = Specifies the folder with the file to select, defaults to $ScriptDirectory\input
    Filter = Filters the files you can choose from, ex. "-Filter "*.csv"" for only csv files
    Prompt = Allows for a custom prompt message like "Select your CSV file" instead of default "Please choose your input file"
    ClearScreen = Clears the console screen when the menu appears. Ex, "Get-Inputfile -ClearScreen"
#>

Function Get-InputFile {
    Param (
        [Alias('dir')]
        [string]$Directory = "$PSScriptRoot\input",
        [Alias('f')]
        [string]$Filter = "*",
        [Alias('p')]
        [string]$Prompt = "Please choose your input file",
        [Alias('c')]
        [switch]$ClearScreen

    )

    If ($ClearScreen) {Clear-Host}

    Function Write-Prompt ($char) { Write-Host -ForegroundColor Black -BackgroundColor White " $char " -NoNewline }

    If (Test-Path $Directory) {$InputFolderPath = "$Directory"}
    Else {Throw "Specified location $Directory does not exist"}

    Try {
        $FileList = Get-ChildItem $InputFolderPath -Filter $Filter
    }
    Catch {
        Write-Host -ForegroundColor Red "Input folder not found at " -NoNewline
        Write-Host -ForegroundColor Yellow $InputFolderPath

        $FileList = "None"
    }

    Do {
        If ($FileList -ne "none") {
            Write-Host
            Write-Host -ForegroundColor Green "$($Prompt): "
            For ($i=0; $i -le ($FileList.Count - 1); $I++){
                Write-Prompt "$($i + 1)"
                Write-Host " $($FileList[$i])"
            }
            Write-Host 
            Write-Prompt "F"
            Write-Host " to enter custom file path"
            
            Write-Prompt "X"
            Write-Host " or " -NoNewline
            Write-Prompt "Exit"
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
