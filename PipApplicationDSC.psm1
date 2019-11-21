enum Ensure { 
    Present
    Absent 
}

[DscResource()]
class PipApplicationDSC {
    
    #region class properties

    [DscProperty(Key)]
    [string]$ApplicationName

    [DscProperty(Key)]
    [String]$Version
    
    [DscProperty(Mandatory)]
    [string]$Path

    [DscProperty(Mandatory)]
    [string]$ExePath    

    [DscProperty(Mandatory)]
    [string]$LogPath    
    
    [DscProperty()]
    [Ensure]$Ensure = [Ensure]::Present

    [DscProperty(NotConfigurable)]
    [string]$Status

    [PipApplicationDSC] Get () {
        if ($this.Ensure -eq [Ensure]::Present) { 
            $this.Status = if ($this.Test()){
                'Installed' 
            } else {
                'NotInstalled' 
            }
        } else {
            $this.Status = if ($this.Test()){
                'NotInstalled' 
            } else {
                'Installed' 
            }    
    
        }
        return $this
    }
    
    [bool] Test () {
        if ($this.Ensure -eq [Ensure]::Present) { 
            try {
                if (-not (Test-Path -Path $this.Path)){
                    Write-Verbose "$($this.Path) Not found"
                    return $false
                }
        
                $targetFolder = Join-Path -Path $this.Path -ChildPath "$($this.ApplicationName)-$($this.Version)"
                if (-not (Test-Path -Path $targetFolder)){
                    Write-Verbose "$targetFolder not found"
                    return $false
                }
        
                $executableFile = Join-Path -Path $targetFolder -ChildPath $this.ExePath
                if (-not (Test-Path -Path $executableFile)){
                    Write-Verbose "$executableFile not found"
                    return $false
                }

                return $true
            } catch {
                Write-Verbose "Test failed Error:  $_ $($_.ScriptStackTrace)"
                return $false
            }
        } else {
            $targetFolder = Join-Path -Path $this.Path -ChildPath "$($this.ApplicationName)-$($this.Version)"
            if ((Test-Path -Path $targetFolder)){
                Write-Verbose "$targetFolder found"
                return $false
            }
            return $true
        }
    }
    
    [void] Set () {
        if ($this.Ensure -eq [Ensure]::Present) { 
            try {
                if (-not (Test-Path -Path $this.Path)){
                    throw "$($this.Path) not found, cannot install when target folder does not exist"
                }
                
                if (-not (Test-Path -Path $this.LogPath)) {
                    throw "$($this.LogPath) not found, cannot install if Log folder does not exist"
                }
            
                $targetFolder = Join-Path -Path $this.Path -ChildPath "$($this.ApplicationName)-$($this.Version)"
                if (Test-Path -Path $targetFolder){
                    Remove-Item -Recurse -Force -Confirm:$false -Path $targetFolder -ErrorAction Stop
                }
            
                virtualenv.exe --system-site-packages $TargetFolder -q
                        
                #do pip install magic
                if($virtualEnvPip = (Get-Item -Path "$targetFolder\Scripts\pip.exe").FullName) {
                    $argumentList = @(
                        'install' 
                        '--disable-pip-version-check'
                        "$($this.ApplicatioNName)==$($this.Version)"
                        '--verbose'
                        '--log'
                         "$($this.LogPath)\$($this.ApplicatioNName)-$($this.Version).log"
                    )
                
                    Start-Process -FilePath $virtualEnvPip -ArgumentList $argumentList -ErrorAction Stop
                }
                else {
                    throw "virtualenv creation failed. Pip.exe could not be found on path $targetFolder\Scripts\pip.exe"
                }            
            } catch {
                Write-Error "Set failed Error:  $_ $($_.ScriptStackTrace)"
            }
        } 
        else {
            $targetFolder = Join-Path -Path $this.Path -ChildPath "$($this.ApplicationName)-$($this.Version)"
            try { 
                Remove-Item -Path $targetFolder -Recurse -Force -ErrorAction Stop
            } catch {
                Write-Error "Cannot remove $targetFolder"
            }
        }
    }
}
