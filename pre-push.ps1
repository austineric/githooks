#!/usr/bin/env pwsh

####################################
# Author:       Eric Austin
# Description:  Pre-push git hook
# Notes:        Copies specified repo items to another location (ie a prod repo)
#               Pre-push hooks receive the following arguments:
#                   $Remote=$Args[0]    #name of remote
#                   $URL=$Args[1]       #location of remote
####################################

#common variables
$CurrentDirectory=[string]::IsNullOrWhiteSpace($PSScriptRoot) ? (Get-Lcation).Path : $PSScriptRoot
$ErrorActionPreference="Stop"

#script variables
$Destination=''         #double-quoted if necessary
$ItemsToCopy=''         #double-quoted (if necessary) comma-separated names of the files and/or folders that should be transferred to the prod repo, ie '"Folder 1", "Folder 2"'
$CopyItemsCommand=""    #instantiate empty

Try {

    Write-Host "---------------"
    Write-Host ""
    Write-Host "Running pre-push hook..."

    #copy specified items (use Invoke-Expression to properly handle multiple items with spaces in their names)
    Write-Host "Copying specified items..."
    $CopyItemsCommand="Copy-Item -Path $CurrentDirectory -Destination $Destination -Include $ItemsToCopy -Recurse"
    Invoke-Expression -Command $CopyItemsCommand

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
