properties {
	#$Template="ttl-windows-2008R2-serverstandard-amd64-winrm"
	$Template="windows_2012.json"	
	$cDir = pwd;			
	$winIsoName = "en_windows_server_2008_r2_with_sp1_x64_dvd_617601.iso"
	$IsoPath = "$cDir\iso"
	$sleepTime = 60
	$memoryGb = 2
	$diskGb = 40
	$cpuCount = 2
	$memorySize = 1024 * $memoryGb	
	$diskSize = 1024 * $diskGb
	$label = 0;
	if(Test-Path env:GO_PIPELINE_LABEL)
	{
		$label = (get-item env:GO_PIPELINE_LABEL).Value
		write-host "found a build label [$label]"
	}
	$version = "1.0.$label"
	$stack = "M" + $memoryGb + "D" + $diskGb + "C" + $cpuCount
	$BuildName = "windows_2012.json"
	$BoxName = "$BuildName" + ".box"
}

#task default -depends Init, KillVirtualBox,  DownloadWindowsIso,  DownloadVirtualBoxAdditionsIso InstallTheOSonTheBaseBox, SleepToLetTheMachineBoot, ExportTheBaseBox, MoveTheBaseBox

task default -depends Init, KillVirtualBox, InstallTheOSonTheBaseBox

#, SleepToLetTheMachineBoot, ExportTheBaseBox, MoveTheBaseBox

task Init {	
	write-host "Building  [$version] ->  $BuildName"
	write-host "Kill any running version of virtual box."		
	if((Test-Path -Path $IsoPath) -eq $false)
	{
		mkdir ($IsoPath)
	}
}

task KillVirtualBox {
	try
	{
		$list = tasklist | select-string "virtualbox.exe"
		if("$list" -ne "")
		{		
			Exec { taskkill /im virtualbox.exe /f}	
		}
	}
	catch
	{
		#Sink any errors. 
	}	
}

task InstallTheOSonTheBaseBox {
	write-host "packer build $BuildName -force "
	Exec { packer build -force "$BuildName"  }
}

task ExportTheBaseBox {
	Exec { vagrant basebox export "$BuildName" --force}
}

task MoveTheBaseBox {
	move $BoxName d:\websites\box\
}

task SleepToLetTheMachineBoot {
	Start-Sleep -s $sleepTime
}

task ? -Description "Helper to display task info" {
    Write-Documentation
}

function SearchReplace {
	param($search="" , $replace="", $path="")	
	$content = [string]::join([environment]::newline, (get-content -path $path))
	$content = $content.replace($search,$replace)	
	$content.replace("`r`n?", "`n")
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [IO.File]::WriteAllText($path, $content, $utf8)
}

function Download {
	param($uri="",$path="")
	write-host $uri
	write-host $path 
	if((Test-Path -Path $path) -eq $false)
	{
		write-host "$path does not exist downloading $uri"
		try
		{
			$clientWin = new-object System.Net.WebClient
			$clientWin.UseDefaultCredentials = $true
			$clientWin.DownloadFile( $uri, $path )
		}
		catch [Net.WebException] 
		{
			$_ | fl * -Force
		}
	}
}


function InstallGem {
	param($name="")
	$x = & gem q | select-string "$name"
	if("$x".Contains("$name") -eq $false)
	{
		Write-host "Install $name"
		Exec { gem install $name } 
	}	
}