C:\Users\dicke\eclipse-workspace\tomcat-eclipse-example. "${PSScriptRoot}\FileRenameMedia.ps1"

$baseDir = "H:\RecoveredData\RAW"
$foldersToLookFor = "mp3*"
$fieldsToUse = @("Album Artist", "Album", "#", "Title")
$procDirFile = "${PSScriptRoot}\processedDirs.txt"
$processedDirs = @()

if (Test-Path $procDirFile)
{
    $processedDirs = Get-Content $procDirFile
}

cd "$baseDir"

gci -Filter $foldersToLookFor | % { 
    if ($_.Name -notin $processedDirs) { 
        Write-Host 'Processing ' $_.FullName
        Rename-MediaFiles $_.FullName $fieldsToUse
        $processedDirs += $_.Name
    }
}

Set-Content -Path $procDirFile $processedDirs

# gci -Filter jpg* | % {
#     $folderName = $_.Name
#     $number = $folderName.Substring(4, 3)
#     if ($number -ge "001" -and $number -le "081")
#     {
#         $processedDirs += $folderName
#     }
# }