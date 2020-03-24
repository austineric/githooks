#!/usr/bin/env pwsh

####################################
# Author:       Eric Austin
# Description:  Pre-push git hook
# Notes:        Copies specified repo items to another location (ie a prod repo) and sets directory permissions as needed
#               Pre-push hooks receive the following arguments:
#                   $Remote=$Args[0]    #name of remote
#                   $URL=$Args[1]       #location of remote
####################################

#declare namespaces
using namespace System.Collections.Generic
using namespace System.Security.AccessControl

#common variables
$ErrorActionPreference="Stop"

#script variables
$Destination=""        #not necessary to double-quote
$ItemsToCopy=@("")         #array of names of the files and/or folders that should be transferred to the prod repo; not necessary to double-quote
$ItemsToExclude='""'      #double-quoted (if necessary), NOT comma-separated names of folders (within ItemsToCopy) that should be ignored (ie a "FilesAlreadyImported" folder that shouldn't be overwritten)
$RobocopyCommand=""    #instantiate empty
[List[string]] $AccessRuleList=@() #instantiate empty

#targeted permissions (repeat for as many targets and users as necessary)
$Target1="$(Join-Path -Path $Destination -ChildPath "")"     #do not double-quote (the Get-Acl command below doesn't handle the double-quoted variable)
$User1=""       #DOMAIN/username       
$AccessRule1=New-Object FileSystemAccessRule("$User1","FullControl","ContainerInherit,Objectinherit","none","Allow")
$AccessControlList1=(Get-Acl -Path $Target1)
$AccessControlList1.SetAccessRule($AccessRule1)
$AccessRuleList.Add("Set-Acl -Path `"$Target1`" -AclObject `$AccessControlList1")

Try {

    Write-Host "---------------"
    Write-Host ""
    Write-Host "Running pre-push hook..."

    Write-Host "Copying specified items..."
    Get-ChildItem | Where-Object -Property Name -In $ItemsToCopy | ForEach-Object {

        #create top level folder(s) if not extant
        if (-not (Test-Path -Path (Join-Path -Path $Destination -ChildPath $_.Name)))
        {
            Copy-Item -Path $_.FullName -Destination $Destination
        }

        #copy specified top-level files and directory contents
        #flags:
            #/e: copies subdirectories, including empty directories
            #/purge: remove destination files/folders that don't exist in source
            #/xd: directories to exclude
            #/njh: no job header
            #/njs: no job summary
            #/nfl: no file names displayed
            #/ndl: no directory names displayed
        $RobocopyCommand="Robocopy `"$($_.FullName)`" `"$(Join-Path -Path $Destination -ChildPath $_.BaseName)`" /e /purge /xd $ItemsToExclude /njh /njs /nfl /ndl"
        #Write-Host $RobocopyCommand
        $ReturnCode=(Invoke-Expression -Command $RobocopyCommand)

        #check return code (https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/robocopy#exit-return-codes)
        if ($ReturnCode -notin @(0, 1, 2, 3))
        {
            Throw "Robocopy returned a return code of $LASTEXITCODE"
        }

    }

    #set permissions
    if ($AccessRuleList.Count -gt 0)
    {
        Write-Host "Setting permissions..."
        $AccessRuleList | ForEach-Object {
            Invoke-Expression -Command $_
        }
    }

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
