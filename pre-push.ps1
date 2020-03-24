#!/usr/bin/env pwsh

####################################
# Author:       Eric Austin
# Description:  Pre-push git hook
# Notes:        Copies specified repo items to another location (ie a prod repo)
#               Pre-push hooks receive the following arguments:
#                   $Remote=$Args[0]    #name of remote
#                   $URL=$Args[1]       #location of remote
####################################

#declare namespaces
using namespace System.Collections.Generic
using namespace System.Security.AccessControl

#common variables
$CurrentDirectory=[string]::IsNullOrWhiteSpace($PSScriptRoot) ? (Get-Location).Path : $PSScriptRoot
$ErrorActionPreference="Stop"

#script variables
$Destination=''         #double-quoted if necessary
$ItemsToCopy=''         #double-quoted (if necessary) comma-separated names of the files and/or folders that should be transferred to the prod repo, ie '"Folder 1", "Folder 2"'
$ItemsToExclude=''      #double-quoted (if necessary) comma-separated names of the files and/or folders (within ItemsToCopy) that should be ignored (ie a "FilesAlreadyImported" folder that shouldn't be overwritten)
$CopyItemsCommand=""    #instantiate empty
[List[string]] $AccessRuleList=@() #instantiate empty

#targeted permissions (repeat for as many targets and users as necessary)
$Target1=''     #double-quoted if necessary
$User1=""       #DOMAIN/username       
$AccessRule1=New-Object FileSystemAccessRule("$User1","FullControl","ContainerInherit,Objectinherit","none","Allow")
$AccessControlList1=(Get-Acl -Path $Target1)
$AccessControlList1.SetAccessRule($AccessRule1)
$AccessRuleList.Add("Set-Acl -Path $Target1 -AclObject `$AccessControlList1")

Try {

    Write-Host "---------------"
    Write-Host ""
    Write-Host "Running pre-push hook..."

    

    #copy specified items (use Invoke-Expression to properly handle multiple items with spaces in their names)
    Write-Host "Copying specified items..."
    $CopyItemsCommand="Copy-Item -Path $CurrentDirectory -Destination $Destination -Include $ItemsToCopy -Exclude $ItemsToExclude -Recurse"
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
