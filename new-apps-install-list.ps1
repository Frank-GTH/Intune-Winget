<#PSScriptInfo
.DESCRIPTION
Creates install-apps input file and updates version
.INPUTS
WinGet app ids
.OUTPUTS
install-apps.txt
.NOTES
  Version:        1.0
  Author:         FL
  Creation Date:  23/11/2022
   
.EXAMPLE
N/A
#>
#####################################################################################################################################
## Variables
$ver = "11" # Change to force install or update

##Winget 3rd party app ids
$apps = @(	"7zip.7zip",
			"Citrix.Workspace",
			"JAMSoftware.TreeSize.Free",
			"Microsoft.VCRedist.2015+.x86",
			"Microsoft.VCRedist.2015+.x64",
			"Notepad++.Notepad++",
			"WhatsApp.WhatsApp"
		)

#####################################################################################################################################
## Constants
$ouputPath = "C:\ProgramData\FKL"					# App install list output dir
$outputFilePath = "$ouputPath\install-apps.txt"		# App install list output full path

#####################################################################################################################################
## Script logic

# Write output for intune AgentExecuter.log output
Write-output "new-apps-install-list.ps1"	# scriptname

# Create and update version
# The version includes Month, Hour and count of apps to make the version change each time the output is created
# Without version change the remediation script will not detect changes and do nothing
$version = "Version $ver." + ((get-date).Month).ToString() + "." + ((get-date).Hour).ToString() + "." + ($apps.count).ToString()

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