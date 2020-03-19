#!/usr/bin/env pwsh

####################################
# Author:       Eric Austin
# Description:  Pre-push git hook
# Notes:        Stops processing if there's an error rather than automatically handle fixes which can become convoluted
#               Pre-push hooks receive the following arguments:
#                   $Remote=$Args[0]
#                   $URL=$Args[1]
####################################

#common variables
$ErrorActionPreference="Stop"

#script variables
$TemporaryBranch=""
$Destination=""
$ItemsToPush=""     #comma-separated names of the files and/or folders that should be pushed to the prod repo
$OriginalBranch=""

Try {

    #get original branch
    $OriginalBranch=(((git branch) | Where-Object { $_ -match "\*" })  -replace "\* ", "")

    Write-Host "---------------"
    Write-Host ""
    Write-Host "Running pre-push hook..."

    #check for outstanding changes
    Write-Host "Checking for outstanding changes..."
    if (-not [string]::IsNullOrWhiteSpace($(git status --porcelain)))
    {
        Throw "Git status returned outstanding changes"
    }

	#switch to new branch
	Write-Host "Switching to temporary branch..."
    git checkout -b $TemporaryBranch --quiet
    if ($LASTEXITCODE -ne 0)
    {
        Throw "Checking out temporary branch failed"
    }

    #remove all files except .git, .gitignore, and the specified directory
    Write-Host "Removing any files that shouldn't be sent to prod repo..."
    Get-ChildItem -Exclude .git\*, .gitignore, $ItemsToPush | Remove-Item -Recurse -Force

    #stage the changes for committing
    Write-Host "Staging changes for commit..."
    git add .
    if ($LASTEXITCODE -ne 0)
    {
        Throw "Staging commit in temporary branch failed"
    }

    #commit the changes
    Write-Host "Committing changes..."
    git commit -m "Automatic branch creation" --quiet
    if ($LASTEXITCODE -ne 0)
    {
        Throw "Commit to temporary branch failed"
    }

    #push the branch (use no-verify to prevent this hook from being called again)
    Write-Host "Pushing temporary branch to prod repo..."
    git push $Destination $TemporaryBranch --no-verify --force --quiet
    if ($LASTEXITCODE -ne 0)
    {
        Throw "Pushing temporary branch to prod repo failed"
    }

    #switch back to original branch
    Write-Host "Switching back to original branch..."
    git checkout $OriginalBranch --quiet
    if ($LASTEXITCODE -ne 0) 
    {
        Throw "Switching back to $OriginalBranch failed"
    }

    #delete temporary branch
    Write-Host "Deleting temporary branch..."
    git branch -D $TemporaryBranch --quiet
    if ($LASTEXITCODE -ne 0) 
    {
        Throw "Deleting temporary branch failed"
    }

}
Catch {

    Write-Host "*****"
    Write-Host "Error message:"
    Write-Host $Error[0]
    Write-Host "*****"
    
	#since this is a pre-push hook returning a non-zero return code prevents the push from happening
    Return 1	

}
Finally {

    Write-Host ""
	Write-Host "---------------"
	
}
