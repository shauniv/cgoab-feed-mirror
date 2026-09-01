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

    # Use redirection operators (*>>), not `2>&1 | ...` - piping native stderr
    # output through the pipeline turns it into a PowerShell ErrorRecord, which
    # $ErrorActionPreference = "Stop" then treats as a terminating exception
    # even when the command actually succeeded (git's own summary line goes to
    # stderr on a normal push). Redirection avoids that; $LASTEXITCODE is the
    # real signal.
    git add feed.xml *>> $logFile
    if ($LASTEXITCODE -ne 0) { throw "git add exited $LASTEXITCODE - see mirror.log" }

    $status = git status --porcelain
    if ($status) {
        git commit -m "Update mirrored feed $([DateTime]::UtcNow.ToString('u'))" *>> $logFile
        if ($LASTEXITCODE -ne 0) { throw "git commit exited $LASTEXITCODE - see mirror.log" }

        git push *>> $logFile
        if ($LASTEXITCODE -ne 0) { throw "git push exited $LASTEXITCODE - see mirror.log" }

        Write-Log "Feed changed - committed and pushed."
    } else {
        Write-Log "No change."
    }
}
catch {
    Write-Log "ERROR: $_"
}
