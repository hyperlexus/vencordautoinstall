<#
.SYNOPSIS
    automates the process of updating, building, and injecting Vencord from source.

.DESCRIPTION
    this script performs the following actions:
    1. navigates to the specified Vencord directory.
    2. runs 'git pull' to fetch the latest updates from the repository.
    3. runs 'pnpm build' to compile the source code.
    4. runs 'pnpm inject' to install Vencord into Discord.

.NOTES
    Author: HyperLexus
    Version: 1.1
    - follow this documentation to install vencord from source: https://docs.vencord.dev/installing/
    - make sure you run through it in its entirety once to eliminate any errors
    - if you want to change the installer's function or destination (stable, canary, ptb, auto), change it in line 71.
    - verify you have git and pnpm installed and available in your system's PATH.
    - the script doesn't have the vencord directory set, so you need to do that.
#>

# --- Configuration ---
# set the full path to your Vencord directory here, where you cloned to. Example: C:\Users\<user>\Documents\Vencord
$vencordDir = "C:\Users\CHANGEME"

# --- Script ---
try {
    # check if directory exists. this will most likely fail the first time, so update this!
    if (-not (Test-Path -Path $vencordDir -PathType Container)) {
        Write-Error "Directory not found: $vencordDir. Please update the `$vencordDir` variable in the script. This is not set by default."
        Read-Host "Press Enter to exit"
        return
    }

    # cd $vencordDir
    Write-Host "✅ Navigating to Vencord directory: $vencordDir" -ForegroundColor Green
    Set-Location -Path $vencordDir

    # --- git pull ---
    Write-Host "`n----------------------------------" -ForegroundColor Cyan
    Write-Host "running 'git pull'..." -ForegroundColor Cyan
    Write-Host "----------------------------------"
    git pull

    # Check the exit code of the last command. 0 means success.
    if ($LASTEXITCODE -ne 0) {
        throw "'git pull' failed. please check for errors above, resolve any merge conflicts and all the other git stuff :)."
    }
    Write-Host "updated successfully." -ForegroundColor Green

    # --- Step 2: PNPM Build ---
    Write-Host "`n----------------------------------" -ForegroundColor Cyan
    Write-Host "running 'pnpm build'..." -ForegroundColor Cyan
    Write-Host "----------------------------------"
    # if you want to build the dev build (for stuff like patch helper), add --dev to this: 'pnpm build --dev'
    pnpm build

    if ($LASTEXITCODE -ne 0) {
        throw "'pnpm build' failed. Please check for errors above."
    }
    Write-Host "Vencord built successfully." -ForegroundColor Green

    # --- Step 3: PNPM Inject ---
    Write-Host "`n----------------------------------" -ForegroundColor Cyan
    Write-Host "running 'pnpm inject'..." -ForegroundColor Cyan
    Write-Host "----------------------------------"
    Write-Host "will automatically select what you set in the lines below." -ForegroundColor Yellow
    
    # automatically patch stable discord. change this if you want the script to do something else, as mentioned above.
    # run pnpm inject --help to get all options
    pnpm inject -install -branch stable

    if ($LASTEXITCODE -ne 0) {
        # Note: The injector might return a non-zero exit code even on success/user cancellation.
        # This message is a general catch-all.
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
    Write-Host "`n`nscript completed. you may now close the window."
    Read-Host "Press Enter to exit"
}
