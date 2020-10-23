#!/bin/env pwsh

####################################
# Author:       Eric Austin
# Description:  Pre-push git hook
# Notes:        Sets permissions as needed
#               Pre-push hooks receive the following arguments:
#                   $Remote=$Args[0]    #name of remote
#                   $URL=$Args[1]       #location of remote
####################################

#declare namespaces
using namespace System.Security.AccessControl

Try {

	#common variables
	$ErrorActionPreference="Stop"

	#script variables
	$ProdRepoLocation="ProdRepoLocationHere"        #not necessary to double-quote

	#targeted permissions must be set in the body of the script (the permissions can't be set until the repo is pushed and the directories exist)

    Write-Host "---------------"
    Write-Host ""
    Write-Host "Running pre-push hook..."

    #push to prod repo
    Write-Host "Pushing to prod repo..."
    git push $ProdRepoLocation master --no-verify --force
    if ($LASTEXITCODE -ne 0)
    {
        Throw "Pushing to prod repo failed"
    }

    Write-Host "Setting permissions..."

    #targeted permissions (repeat for as many targets and users as necessary)
    $Target="$(Join-Path -Path $ProdRepoLocation -ChildPath "TargetedDirectoryHere")"     #do not double-quote (the Get-Acl command below doesn't handle the double-quoted variable)
    $User="DOMAIN\UsernameHere"       #DOMAIN\username
    $AccessRule=New-Object FileSystemAccessRule("$User","FullControl","ContainerInherit,Objectinherit","none","Allow")
    $AccessControlList=(Get-Acl -Path $Target)
    $AccessControlList.SetAccessRule($AccessRule)
    Set-Acl -Path $Target -AclObject $AccessControlList

    Write-Host "Success"
    Exit 0    #return success code of 0

}
Catch {

    Write-Host "*****"
    Write-Host "Error message:"
    Write-Host $Error[0]
    Write-Host "*****"
    
	#returning a non-zero code prevents the action from happening
    Exit 1	

}
Finally {

    Write-Host ""
	Write-Host "---------------"
	
}
