# 8/3/2022
#File Integrity Monitor

Function Calculate-File-Hash($filepath) {
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}


Function Erase-Baseline-If-Exists() {
    $baselineExists = Test-Path -Path .\baseline.txt

    if ($baselineExists) {
        Write-Host "Baseline already exists, deleting."
        Remove-Item -Path .\baseline.txt
    }
}
Write-Host ""
Write-Host "FILE INTEGRITY MONITOR"
Write-Host ""
Write-Host "    [1] Establish a baseline"
Write-Host "    [2] Begin monitoring files with saved baseline?"
Write-Host ""

$choice = Read-Host -Prompt "Choice: "


Write-Host ""

if($choice -eq 1) {
    #Overview: Calculate hash from the target files and store in baseline.txt

    Erase-Baseline-If-Exists

    Write-Host "Calculating hashes and creating baseline.txt"
    
    #Step 1: collect all files in the target foler.
    $files = Get-ChildItem -Path .\files

    #Step 2: Calculate hash for each file and write to baseline.txt
    foreach ($f in $files) {
        $hash = Calculate-File-Hash $f.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
    }
      
}
elseif($choice -eq 2) {

    $fileHashDictionary = @{}
    
    $filePathsAndHashes = Get-Content -Path .\baseline.txt

    foreach($f in $filePathsAndHashes) {
        $fileHashDictionary.add($f.Split("|")[0],$f.Split("|")[1])       
    }

    while ($true) {
        Start-Sleep -Seconds 1
    
        $files = Get-ChildItem -Path .\files
    
        foreach($f in $files) {
            $hash = Calculate-File-Hash $f.Fullname

            # Notifies if new files are created.
            if($fileHashDictionary[$hash.Path] -eq $null) {
                Write-Host "[CREATED]  [TIME] $(Get-Date) [PATH] $($hash.Path)" -ForegroundColor White
            }
            else {
                   # Notifies if files are changed.
                if ($fileHashDictionary[$hash.Path] -eq $hash.Hash) {
                    #Files are the same.
                } else {
                    #Files have changed.

                    Write-Host "[MODIFIED] [TIME] $(Get-Date) [PATH] $($hash.Path)" -ForegroundColor Yellow
                }
            }
         
        }

        foreach($key in $fileHashDictionary.keys) {
            $baselineFileStillExists = Test-Path $key
            if (-Not $baselineFileStillExists) {
                Write-Host "[DELETED]  [TIME] $(Get-Date) [PATH] $($key)" -ForegroundColor Red
            }
        }
    }
}
