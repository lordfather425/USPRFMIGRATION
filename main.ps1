$ErrorActionPreference = 'Stop'

$computerName = Read-Host "Enter the name of the remote computer"
$usernames = Get-ChildItem -Path "\\$computerName\C$\Users" -Directory | Select-Object -ExpandProperty Name | Out-GridView -Title "Select a user" -PassThru

if ($usernames) {
    $sourceFolders = @(
        "\\$computerName\C$\Users\$usernames\Downloads"
        "\\$computerName\C$\Users\$usernames\Documents"
        "\\$computerName\C$\Users\$usernames\Desktop"
        "\\$computerName\C$\Users\$usernames\Favorites"
        "\\$computerName\C$\Users\$usernames\Pictures"
        "\\$computerName\C$\Users\$usernames\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"
        "C:\con2prt.exe"
        "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\Con2prt.cmd"
    )

    $totalSize = 0
    foreach ($folder in $sourceFolders) {
        if (Test-Path $folder) {
            $totalSize += (Get-ChildItem $folder -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        }
    }

    $totalSizeInMB = [math]::Round(($totalSize / 1MB), 2)
    $message = "Total size of folders to be copied is $totalSizeInMB MB. Do you want to proceed?"
    $result = Read-Host -Prompt $message

    if ($result -eq "Y" -or $result -eq "y") {
        $destFolder = "H:\$computerName\$usernames"

        New-Item -ItemType Directory -Path $destFolder -ErrorAction SilentlyContinue | Out-Null

        foreach ($folder in $sourceFolders) {
            if (Test-Path $folder) {
                $folderName = (Split-Path -Path $folder -Leaf)
                $destFolderPath = Join-Path -Path $destFolder -ChildPath $folderName

                if (!(Test-Path -Path $destFolderPath)) {
                    New-Item -ItemType Directory -Path $destFolderPath -ErrorAction SilentlyContinue | Out-Null
                }

                Get-ChildItem -Path $folder -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                    $relativePath = $_.FullName.Replace($folder, "")
                    $destFilePath = Join-Path -Path $destFolderPath -ChildPath $relativePath

                    if (!(Test-Path -Path $destFilePath)) {
                        New-Item -ItemType Directory -Path (Split-Path -Path $destFilePath -Parent) -ErrorAction SilentlyContinue | Out-Null
                    }

                    Copy-Item -Path $_.FullName -Destination $destFilePath -Force -ErrorAction SilentlyContinue
                }
            }
        }

        Write-Host "Folders copied to $destFolder"
    } else {
        Write-Host "User canceled the operation."
    }
} else {
    Write-Host "No user selected. Exiting script."
}

Read-Host "Press Enter to exit"
