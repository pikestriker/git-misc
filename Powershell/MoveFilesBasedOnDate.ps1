$baseDir = "\\10.0.0.91\homeshare\RecoveredData\RAW"
$destBaseDir = "\\10.0.0.91\homeshare\Pictures"

gci $baseDir -Filter jpg* | % {
    $curDir = $baseDir + "\" + $_.Name
    $curDir

    gci $curDir | % {
        $curFile = $_.Name
        # $curFile

        if ($curFile -match "(\d+)-.(\d+)-.(\d+)")
        {
            # $matches[1]

            $destDir = $destBaseDir + "\" + $matches[1] + "\" + $matches[2] + "\" + $matches[3]

            if (-not (Test-Path $destDir))
            {
                mkdir $destDir
            }

            $destFileName = $destDir + "\" + $curFile
            $curFileNoExt = $curFile.Substring(0, $curFile.LastIndexOf("."))
            $fileExt = $curFile.Substring($curFile.LastIndexOf("."))
            
            $curFileCount = 0
            while (Test-Path $destFileName)
            {
                $curFileCount += 1
                $destFileName = $destDir + "\" + $curFileNoExt + $curFileCount + $fileExt
            }

            $curFile = $_.FullName
            Move-Item $curFile $destFileName
        }
    }
}