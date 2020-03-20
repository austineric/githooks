#!/usr/bin/env pwsh

####################################
# Author:       Eric Austin
# Description:  Pre-push git hook
# Notes:        Pushes the repo to a specified location then removes unnecessary items
#               Pre-push hooks receive the following arguments:
#                   $Remote=$Args[0]
#                   $URL=$Args[1]
####################################

#common variables
$ErrorActionPreference="Stop"

#script variables
$Destination=''         #double-quoted if necessary
$ItemsToKeep=''         #comma-separated names of the files and/or folders that should be pushed to the prod repo, double-quoted if necessary, ie '"Folder 1", "Folder 2"'
$CurrentBranch=""       #instantiate empty
$RemoveItemsCommand=""  #instantiate empty

Try {

    #get current branch
    $CurrentBranch=(((git branch) | Where-Object { $_ -match "\*" })  -replace "\* ", "")

    Write-Host "---------------"
    Write-Host ""
    Write-Host "Running pre-push hook..."

    #check for outstanding changes
    Write-Host "Checking for outstanding changes..."
    if (-not [string]::IsNullOrWhiteSpace($(git status --porcelain)))
    {
        Throw "Git status returned outstanding changes"
    }

    #push the branch (use no-verify to prevent this hook from being called again)
    Write-Host "Pushing to prod repo..."
    git push $Destination $CurrentBranch --no-verify --force --quiet
    if ($LASTEXITCODE -ne 0)
    {
        Throw "Pushing to prod repo failed"
    }

    #remove unnecessary items (use Invoke-Expression to properly handle multiple items with spaces in their names)
    Write-Host "Removing unnecessary items..."
    $RemoveItemsCommand="Get-ChildItem -Path $Destination -Exclude .git\*, .gitignore, $ItemsToKeep | Remove-Item -Recurse -Force"
    Invoke-Expression -Command $RemoveItemsCommand

    Write-Host "Success"
    Return 0    #return success code of 0

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
