#####################################################################################
#   Fn Get-InputFile
#####################################################################################
<#
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