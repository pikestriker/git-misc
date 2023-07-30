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
        # be applied to all different file types)
        # TODO: merge folders with similar filenames so that you can keep old files (one folder has song.mp3 and
        # another folder has song.mp3, merge to a single folder so we have song.mp3 and song1.mp3)

        $newFileName = $null
        $fileName = $result.Name + $result.'File extension'
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
        #Rename-Item $fileName $finalFileName
    }
}