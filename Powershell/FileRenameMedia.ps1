function Rename-MediaFiles ($feederDir, $fieldsToUse)
{
    if ($feederDir -eq $null -or $fieldsToUse -eq $null)
    {
        Write-Host "Please supply the feeder directory and the fields to use"
    }
    # $feederDir = "H:\RecoveredData\RAW\m4a"

    $results = Get-FileMetaData -Folder $feederDir

    cd $feederDir

    $fileList = @{}

    Write-Host 'Metadata fields used:'
    $fieldsToUse

    foreach ($result in $results)
    {
        # rename the file based on Authors - Title
        # keep a hash map of the files with the same name
        # TODO: remove illegal characters (', ", :, /, \, ?, *, <, >) - done
        # TODO: make this a function and pass in the list of fields to make up the filename (so that it can
        # be applied to all different file types) - done
        # TODO: merge folders with similar filenames so that you can keep old files (one folder has song.mp3 and
        # another folder has song.mp3, merge to a single folder so we have song.mp3 and song1.mp3)

        $newFileName = $null
        $fileExt = $result.'File Extension'
        $fileName = $result.Name
        if ($fileName.Substring($fileName.Length - $fileExt.Length) -ne $fileExt)
        {
            $fileName = $result.Name + $result.'File extension'
        }
        foreach ($field in $fieldsToUse)
        {
            if ($newFileName -eq $null)
            {
                if ($result.$field -ne $null)
                {
                    $newFileName = $result.$field
                }
            }
            else
            {
                if ($result.$field -ne $null)
                {
                    $newFileName = $newFileName + ' - ' + $result.$field
                }
            }
        }

        if ($newFileName -eq $null)
        {
            Write-Host 'Skipping File ' $fileName ' cannot find values for metadata fields'
            continue
        }

        $newFileName = $newFileName -replace "[`":/\\?*<>']", '-'
    
        $finalFileName = $newFileName

        if ($newFileName -in $fileList.Keys)
        {
            $number = $fileList[$newFileName]
            $finalFileName = $newFileName + $number + $result.'File extension'
            $number++
            $fileList[$newFileName] = $number
        }
        else
        {
            $finalFileName = $newFileName + $result.'File extension'
            $fileList[$newFileName] = 1
        }

        Write-Host 'Renaming ' $fileName ' to ' $finalFileName
        Rename-Item $fileName $finalFileName
    }
}

function Move-MediaFiles ($sourceDir, $destDir, $hashCheck)
{
    # this will move the media file from the source directory to a destination directory
    # it will also take into consideration the file names and rename it to something different
    # also check to see if the files are different and just delete the second file
    $files = gci -Path $destDir | % { $_.Name }

    # TODO: add the ability to recurse

    $fileNames = @{}
    foreach ($file in $files)
    {
        $fileNames.Add($file.Substring(0, $file.LastIndexOf('.')), 0)
    }

    $filesSourceDir = gci -Path $sourceDir | % { $_.Name }

    foreach ($file in $filesSourceDir)
    {
        $fileName = $file.Substring(0, $file.LastIndexOf('.'))
        $ext = $file.Substring($file.LastIndexOf('.'))
        $srcFile = $sourceDir + "\" + $file
        $destFile = $destDir + "\" + $file
        if ($fileNames[$fileName] -ne $null)
        {
            # There is a matching file in the destination directory
            $srcHash = '1'
            $destHash = '2'
            if ((gci $srcFile).Length -eq (gci $destFile).Length -and $hashCheck)
            {
                $srcHash = (Get-FileHash -Algorithm MD5 $srcFile).hash
                $destHash = (Get-FileHash -Algorithm MD5 $destFile).hash
            }

            if ($srcHash -ne $destHash)
            {
                $number = $fileNames[$filename]
                $number++
                
                $newFileName = $fileName + $number
                while ($fileNames[$newFileName] -ne $null)
                {
                    $number++
                    $newFileName = $fileName + $number
                }
                $fileNames[$newFileName] = 0
                $fileNames[$filename] = $number
                $destFile = $destDir + "\" + $fileName + $number + $ext

                # this is dumb, apparently powershell doesn't like file names with the square
                # brackets in the filename so you have to double escape them to allow them to go
                # https://stackoverflow.com/questions/21008180/copy-file-with-square-brackets-in-the-filename-and-use-wildcard
                # $destFile = $destFile.Replace('[', '``[').Replace(']', '``]')
                # and apparently it is only the source file, hence the commented out line above :P
                $srcFile = $srcFile.Replace('[', '``[').Replace(']', '``]')
                Write-Host 'Moving file from ' $srcFile ' to ' $destFile
                Move-Item "$srcFile" "$destFile"
            }
            else
            {
                #hashes match remove the source file
                Write-Host 'Removing Item ' $srcFile
                Remove-Item "$srcFile"
            }
        }
        else
        {
            $srcFile = $srcFile.Replace('[', '``[').Replace(']', '``]')
            $fileNames[$fileName] = 0
            Write-Host 'Moving file from ' $srcFile ' to ' $destFile
            Move-Item "$srcFile" "$destFile"
        }
    }
}