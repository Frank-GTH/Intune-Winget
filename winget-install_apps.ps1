<#PSScriptInfo
.DESCRIPTION
Installs applications via Winget from input list
.INPUTS
App list file: install-apps.txt
.OUTPUTS
Log files: Winget.@.Remediation.log + WinGet.App ID.Install.log + WinGet.App ID.Install.log + WinGet.App ID.Update.log
.NOTES
  Version:        1.0.0
  Author:         FL
  Creation Date:  03/12/2022
.EXAMPLE
N/A
#>
#####################################################################################################################################
##Constants
$input = "C:\ProgramData\FKL\install-apps.txt"		# App install list input file
$AppLog = "C:\ProgramData\FKL\Logs"					# Winget logs dir
$logFilePath = "$AppLog\Winget.@.Remediation.log"	# Winget remediation log full path
$AppList = "C:\ProgramData\FKL\AppList"				# App lists dir old/new
$listFilePath = "$AppList\install-apps.txt"			# App install list full path
$oldFilePath = "$AppList\install-apps-old.txt"		# App install list old full path

#####################################################################################################################################
## Script logic

# Create a folder to store the app lists
If(!(Test-Path $AppList)){
    Start-Sleep 1
    New-Item -Path "$AppList" -ItemType Directory
    Write-host "The folder $AppList was successfully created."
}

# Create a folder to store the logs
If(!(Test-Path $AppLog)){
    Start-Sleep 1
    New-Item -Path "$AppLog" -ItemType Directory
    Write-host "The folder $AppLog was successfully created."
}

# When in remediation mode, always exit successfully as we already remediated during the detection phase
$mode = $MyInvocation.MyCommand.Name.Split(".")[0]
If($mode -eq "remediate"){
    Exit 0
}
# When in detection mode
Else{
	# Check if app list versions are identical,
	# which means no changes or we're in the 2nd detection run where nothing should happen except posting the output to Intune

    # Get app list input file
    If(Test-path $input){
        Copy-Item $input -Destination $listFilePath
    }
    Else{
        # Write Intune post-remediation detection output
		Write-output "$input not found" > $logFilePath
        Exit 0
    }

    # Compare app list version
    If (Test-Path $oldFilePath) {
        $newcontent = get-content $listFilePath | select-object -first 1
        $oldcontent = get-content $oldFilePath | select-object -first 1
        # If files identical
        If ($newcontent -eq $oldcontent) {
	        remove-item -path $listFilePath -force
      	    # Write Intune AgentExecuter.log output (last line also in post-remediation detection output)
			If(Test-path $logFilePath){
				$output = Get-content $logFilePath
				Foreach($line in $output){ Write-host $line }
				Exit 0
			}
			Else{
				# Write Intune post-remediation detection output
				Write-output "Compliant, but no output detected $(get-date)"	
				Exit 0
			}				
		}
    }
}

### So, when in 1st detection phase

# Write output
Write-output "winget-install_apps.ps1" > $logFilePath # script name

# Check AppInstaller/Winget
$AppInstaller = Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq Microsoft.DesktopAppInstaller

If($AppInstaller.Version -lt "2022.506.16.0") {
	
	Write-host "Winget is not installed, trying to install latest version from Github" -ForegroundColor Yellow
	
	Try {
			
		Write-Host "Creating Winget Packages Folder" -ForegroundColor Yellow
		if (!(Test-Path -Path C:\ProgramData\WinGetPackages)) {
			New-Item -Path C:\ProgramData\WinGetPackages -Force -ItemType Directory
		}
		Set-Location C:\ProgramData\WinGetPackages

		# Downloading Packagefiles
		# Microsoft.UI.Xaml.2.7.0
		Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.0" -OutFile "C:\ProgramData\WinGetPackages\microsoft.ui.xaml.2.7.0.zip"
		Expand-Archive C:\ProgramData\WinGetPackages\microsoft.ui.xaml.2.7.0.zip -Force
		# Microsoft.VCLibs.140.00.UWPDesktop
		Invoke-WebRequest -Uri "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" -OutFile "C:\ProgramData\WinGetPackages\Microsoft.VCLibs.x64.14.00.Desktop.appx"
		# Winget
		Invoke-WebRequest -Uri "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -OutFile "C:\ProgramData\WinGetPackages\Winget.msixbundle"
		# Installing dependencies + Winget
		Add-ProvisionedAppxPackage -online -PackagePath:.\Winget.msixbundle -DependencyPackagePath .\Microsoft.VCLibs.x64.14.00.Desktop.appx,.\microsoft.ui.xaml.2.7.0\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.Appx -SkipLicense
		Write-Host "Starting sleep for Winget to initiate" -Foregroundcolor Yellow
		Start-Sleep 2
	}
	Catch {
		# Write Intune post-remediation detection output
		Throw "Failed to install Winget" >> $logFilePath
		Break
	}
}
	
# Find Winget.exe path
$ResolveWingetPath = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe"
if ($ResolveWingetPath){
	$WingetPath = $ResolveWingetPath[-1].Path
}
$winget = "$WingetPath\Winget.exe"

# Loop through copy of app list
$version = get-content $listFilePath | select-object -first 1
"AppInstall list $version" >> $logFilePath
$apps = get-content $listFilePath | select-object -skip 1

# Install/update each app id
$i = 0
$u = 0
$e = 0
foreach ($app in $apps) {
	# Check if app installed
	If((& $winget list --id $app --accept-source-agreements) -contains "No installed package found matching input criteria."){
		
		# Install
		(get-date) > "$AppLog\WinGet.$App.Install.log" 2>&1
		& $winget install --exact --id $app --silent --accept-source-agreements --accept-package-agreements >> "$AppLog\WinGet.$App.Install.log" 2>&1
		Start-sleep -s 3
		$result = get-content "$AppLog\WinGet.$App.Install.log"
		If($result -match "Successfully installed"){
			"$app - installed $(get-date)" >> $logFilePath
			$i++
		}
		Else{
			"$app - error installing $(get-date)" >> $logFilePath
			$e++
		}
	}
	Else{
		# Update
		(get-date) > "$AppLog\WinGet.$App.Update.log" 2>&1
		& $winget upgrade --exact --id $app --silent --accept-source-agreements --accept-package-agreements >> "$AppLog\WinGet.$App.Update.log" 2>&1
		Start-sleep -s 3
		$result = get-content "$AppLog\WinGet.$App.Update.log" | select-object -last 3
		If($result -match "No applicable update found"){
			"$app - nothing to upgrade $(get-date)" >> $logFilePath
		}
		ElseIf($result -match "Successfully installed"){
			"$app - upgraded $(get-date)" >> $logFilePath
			$u++
		}
		Else{
			"$app - error upgrading $(get-date)" >> $logFilePath
			$e++
		}
	}
} 6>$null

# Delete the .old file to replace it with the new one
If (Test-Path $oldFilePath) { remove-item $oldFilePath -Force }
rename-item $listFilePath $oldFilePath

# Write output to logfile
& { write-output "$u apps upgraded, $i apps installed, $e error(s) found $(get-date)" >> $logFilePath } 6>$null
# Write Intune post-remediation detection output
write-output "Winget apps remediation ran succesfully at $(get-date)"
exit 1