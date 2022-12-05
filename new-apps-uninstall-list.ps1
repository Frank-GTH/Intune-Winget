<#PSScriptInfo
.DESCRIPTION
Creates uninstall-apps input file and updates version
.INPUTS
WinGet app ids
.OUTPUTS
uninstall-apps.txt
.NOTES
  Version:        1.0
  Author:         FL
  Creation Date:  23/11/2022
   
.EXAMPLE
N/A
#>
#####################################################################################################################################
## Variables
$ver = "1" # Change to force uninstall

##Winget 3rd party app ids
$apps = @( "7zip.7zip" )

#####################################################################################################################################
## Constants
$ouputPath = "C:\ProgramData\FKL"					# App uninstall list output dir
$outputFilePath = "$ouputPath\uninstall-apps.txt"	# App uninstall list output full path

#####################################################################################################################################
## Script logic

# Write output for intune AgentExecuter.log output
Write-output "new-apps-uninstall-list.ps1"		# scriptname

# Create and update version
# The version is static so nothing happens when same version is detected (no 2nd uninstall)
$version = "Version $ver."

##Create the folder to store the output
If(!(Test-Path $ouputPath)){
    Start-Sleep 1
    New-Item -Path "$ouputPath" -ItemType Directory
}

# Create the output file
If(Test-path $outputFilePath){ remove-item $outputFilePath -Confirm:$false -Force }
$version | add-content $outputFilePath
$apps | add-content $outputFilePath

# Write intune pre-remediation detection output
Write-output "$version created $(get-date)"
exit 0