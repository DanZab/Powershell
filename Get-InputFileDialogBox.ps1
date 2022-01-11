Function Get-InputFileDialogBox {
    Param(
        [string]$DefaultPath = "C:\",
        [string]$FileTypeFilter
    )

    Add-Type -AssemblyName System.Windows.Forms

    # DefaultPath Environment Variables:
    # Use 'dir env:' to list environment variables
    # Use '[Environment]::GetEnvironmentVariable('$VariableName')' to use a variable from that list

    # FileTypeFilter Variable Format:
    # 'Dropdown Value Name'|'File Type filter'|..
    # 'CSV (*.csv)|*.csv|Documents (*.docx)|*.docx|SpreadSheet (*.xlsx)|*.xlsx'

    If ($FileTypeFilter) {
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
            InitialDirectory = $DefaultPath 
            Filter = $FileTypeFilter
        }
    } Else {
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
            InitialDirectory = $DefaultPath 
        }
    }

    # Displays dialog box (the .ShowDialog method does not return any values)
    $null = $FileBrowser.ShowDialog()

    # The selected file returns information in the $FileBrowser variable
    $FilePath = $FileBrowser.FileName

    return $FilePath
}

Get-InputFileDialogBox -DefaultPath $([Environment]::GetEnvironmentVariable('OneDriveCommercial')) -FileTypeFilter "CSV (*.csv)|*.csv|Documents (*.docx)|*.docx|SpreadSheet (*.xlsx)|*.xlsx"