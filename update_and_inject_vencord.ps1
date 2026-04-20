<#
.SYNOPSIS
    automates the process of updating, building, and injecting Vencord from source.

.DESCRIPTION
    this script performs the following actions:
    1. navigates to the specified Vencord directory.
    2. runs 'git pull' to fetch the latest updates from the repository.
    3. runs 'pnpm build' to compile the source code.
    4. detects missing dependencies and automatically runs 'pnpm install --frozen-lockfile' before retrying.
    5. runs 'pnpm inject' to install Vencord into Discord.

.NOTES
    Author: HyperLexus
    Version: 1.2
    - follow this documentation to install vencord from source: https://docs.vencord.dev/installing/
    - make sure you run through it in its entirety once to eliminate any errors
    - if you want to change the installer's function or destination (stable, canary, ptb, auto), change it in line 105.
    - verify you have git and pnpm installed and available in your system's PATH.
    - the script doesn't have the vencord directory set, so you need to do that.
#>

# --- Configuration ---
# set the full path to your Vencord directory here, where you cloned to. Example: C:\Users\<user>\Documents\Vencord
$vencordDir = "C:\Users\HyperLexus\Documents\Vencord"


try {
    # check if directory exists. this will most likely fail the first time, so update this!
    if (-not (Test-Path -Path $vencordDir -PathType Container)) {
        Write-Error "Directory not found: $vencordDir. Please update the `$vencordDir` variable in the script. This is not set by default."
        Read-Host "Press Enter to exit"
        return
    }

    # cd $vencordDir
    Write-Host "navigating to Vencord directory: $vencordDir" -ForegroundColor Green
    Set-Location -Path $vencordDir

    # --- git pull ---
    Write-Host "`n----------------------------------" -ForegroundColor Cyan
    Write-Host "running 'git pull'..." -ForegroundColor Cyan
    Write-Host "----------------------------------" -ForegroundColor Cyan
    git pull

    # Check the exit code of the last command. 0 means success.
    if ($LASTEXITCODE -ne 0) {
        throw "'git pull' failed. please check for errors above, resolve any merge conflicts and all the other git stuff :)."
    }
    Write-Host "updated successfully." -ForegroundColor Green

    Write-Host "`n----------------------------------" -ForegroundColor Cyan
    Write-Host "running 'pnpm build' (with auto-fix attempt)..." -ForegroundColor Cyan
    Write-Host "----------------------------------" -ForegroundColor Cyan

    $maxRetries = 1
    $retryCount = 0
    $buildComplete = $false

    while ($retryCount -le $maxRetries -and -not $buildComplete) {
        # bash in a nutshell
        $buildOutput = & pnpm build 2>&1
        $buildOutput | Write-Host

        # command failure
        if ($LASTEXITCODE -ne 0) {
            $errorPattern = "Could not resolve .*$|module '.*' not found"

            # missing dependency + not enough retries
            if ($buildOutput -match $errorPattern -and $retryCount -lt $maxRetries) {
                Write-Host "`nmissing dependencies detected." -ForegroundColor Yellow
                Write-Host "Running 'pnpm install --frozen-lockfile' to attempt to fix..." -ForegroundColor Yellow

                pnpm install --frozen-lockfile
                if ($LASTEXITCODE -ne 0) {
                    throw "'pnpm install' failed during dependency fix attempt. Cannot continue."
                }

                $retryCount++
                Write-Host "Retrying 'pnpm build'..." -ForegroundColor Cyan
            } else {
                $detailedErrorText = ($buildOutput | Out-String).Trim()
                throw "'pnpm build' failed. Detailed output:\n$detailedErrorText"
            }
        } else {
            $buildComplete = $true
            Write-Host "Vencord built successfully." -ForegroundColor Green
        }
    }

    Write-Host "`n----------------------------------" -ForegroundColor Cyan
    Write-Host "running 'pnpm inject'..." -ForegroundColor Cyan
    Write-Host "----------------------------------" -ForegroundColor Cyan
    Write-Host "will automatically select what you set in the lines below." -ForegroundColor Yellow

    # automatically patch stable discord. change this if you want the script to do something else, as mentioned above.
    # run pnpm inject --help to get all options
    pnpm inject -install -branch stable

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "'pnpm inject' finished with a non-zero exit code. This might not indicate a problem. Please check the output above."
    } else {
        Write-Host "Vencord injection process completed." -ForegroundColor Green
    }

}
catch {
    # catch anything that would terminate
    Write-Error "An error occurred: $_"
}
finally {
    # finally its over
    Write-Host "`n`nScript finished. You can close this window."
    Read-Host "Press Enter to exit"
}