Function Get-Folder($initialDirectory="") {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = "Select a folder"
    $foldername.rootfolder = "MyComputer"
    $foldername.SelectedPath = $initialDirectory

    if($foldername.ShowDialog() -eq "OK")
    {
        $folder += $foldername.SelectedPath
    }
    return $folder
}

# get backup path from windows directory dialog
$backupPath = Get-Folder
echo "found $backupPath"

# do a safty check to ensure that mum did not select C:\ as here backup disk
if ($backupPath -contains "C:\") {
    $Result = [System.Windows.Forms.MessageBox]::Show("Hallo Mama, aus irgendeinem Grund hast als Ziel-Festplatte C:/ ausgew�lt.$([System.Environment]::NewLine)" +
        "Das war keine gute Idee :P Aus Sicherheitsgr�nden breche ich mal ab ;)","Mamas Backup",1,[System.Windows.Forms.MessageBoxIcon]::Error)
        Write-Error 'C:\ choosen --> ERROR' -ErrorAction Stop
}

# show mum the disk she selected and ask if she really wants to use this for her backup
$Result = [System.Windows.Forms.MessageBox]::Show("Hallo Mama, du hast die Ziel-Festplatte $backupPath ausgew�lt.$([System.Environment]::NewLine)" +
        "M�chten du das Backup Starten?","Mamas Backup",3,[System.Windows.Forms.MessageBoxIcon]::Exclamation)

If($Result -eq "Yes") {
    echo "User started backup"

} elseif ( $Result -eq "No") {
    echo "User declined backup"
    break
} else {
    echo "User aborted backup"
    break
}

# define path for csv file which defines backup rules
$path = "C:\Users\Karin\Desktop\Backup\Backup.csv"

# import csv
$csv = Import-Csv -path $path

# loop over csv file, get source and dest path from every line
# and start robocopy command to copy everything from source to dest path
foreach($line in $csv) {
    $properties = $line | Get-Member -MemberType Properties
    for($i=0; $i -lt $properties.Count;$i++) {
        $column = $properties[$i]
        $value=$column.Definition
        if ($i -eq 0) {
            $dest = $backupPath + $value.Substring($value.IndexOf("=")+1)
        } elseif ( $i -eq 1) {
            $source = $value.Substring($value.IndexOf("=")+1)
        }
    }

    echo "found copy command to copy from '$source' --to--> '$dest'"
    robocopy $source $dest /MIR /COPYALL
}
