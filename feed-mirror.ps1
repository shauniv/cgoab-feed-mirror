# feed-mirror.ps1
# Fetches the crazyguyonabike RSS feed (which blocks cloud/datacenter IPs
# but allows normal browser/residential requests) and pushes it into this
# git repo, so dlvr.it/IFTTT can read the mirrored copy instead.
#
# Registered via Task Scheduler - see the schtasks command in the setup notes.

$ErrorActionPreference = "Stop"

$repoPath  = "C:\Users\shaun\source\repos\cgoab-feed-mirror"
$feedUrl   = "https://www.crazyguyonabike.com/doc/rss/?doc_id=27166"
$userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"
$logFile   = Join-Path $repoPath "mirror.log"

function Write-Log($msg) {
    "$([DateTime]::UtcNow.ToString('u')) $msg" | Out-File -FilePath $logFile -Append -Encoding utf8
}

try {
    Set-Location $repoPath

    $tempFile = Join-Path $repoPath "feed.xml.tmp"
    Invoke-WebRequest -Uri $feedUrl -UserAgent $userAgent `
        -Headers @{ "Accept" = "application/rss+xml, application/xml, text/xml, */*" } `
        -OutFile $tempFile -TimeoutSec 30 -UseBasicParsing

    $content = Get-Content $tempFile -Raw

    if ($content -notmatch "<rss") {
        Write-Log "Fetched content doesn't look like RSS - aborting without committing."
        Remove-Item $tempFile -Force
        exit 1
    }

    Move-Item -Force $tempFile "feed.xml"

    git add feed.xml
    $status = git status --porcelain
    if ($status) {
        git commit -m "Update mirrored feed $([DateTime]::UtcNow.ToString('u'))" | Out-Null
        git push 2>&1 | Out-File -FilePath $logFile -Append -Encoding utf8
        Write-Log "Feed changed - committed and pushed."
    } else {
        Write-Log "No change."
    }
}
catch {
    Write-Log "ERROR: $_"
}
