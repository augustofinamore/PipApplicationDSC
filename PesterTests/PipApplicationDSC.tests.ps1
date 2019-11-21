using module ..\PipApplicationDsc\PipApplicationDSC.psd1

Import-Module $PSScriptRoot\StubModules\NativeCommands.Stub.psm1 -force

InModuleScope PipApplicationDSC {
    $module = Get-Module -Name PipApplicationDSC
    $resources = $module.ExportedDscResources

    switch ($resources) {
        PipApplicationDSC {
            $PipApplicationDSC = [PipApplicationDSC]@{
                ApplicationName = 'TargetApplication'
                Version = '1.2.3'
                Path = 'testdrive:\virtualenvs'
                ExePath = 'File.exe'
                LogPath = 'testdrive:\logs'
                Status = 'Installed'
                Ensure = [Ensure]::Present
            }
        
            Describe "Testing methods in $_" {
            
                BeforeEach {
                    New-Item -ItemType Directory -Path 'Testdrive:\virtualenvs\' -Force
                    New-Item -ItemType Directory -Path 'Testdrive:\Logs\' -Force
                    New-Item -ItemType Directory -Path 'Testdrive:\virtualenvs\TargetApplication-1.2.3\' -Force
                }
                
                Mock -CommandName Remove-Item -MockWith {
                    $fullPath = Convert-Path -Path 'Testdrive:\virtualenvs\TargetApplication-1.2.3\'
                    [System.IO.Directory]::Delete($fullPath, $true)
                }
                
                Mock -CommandName virtualenv.exe -MockWith {
                    New-Item -ItemType Directory -Path 'Testdrive:\virtualenvs\TargetApplication-1.2.3\Scripts'
                    New-Item -ItemType File -Path 'Testdrive:\virtualenvs\TargetApplication-1.2.3\Scripts\Pip.exe'
                }
                
                Mock -CommandName Start-Process {
                    New-Item -ItemType File -Path 'Testdrive:\virtualenvs\TargetApplication-1.2.3\Scripts\File.exe'
                }

                Mock -CommandName Get-Item -MockWith {
                    [pscustomobject]@{
                        FullName = 'Testdrive:\virtualenvs\TargetApplication-1.2.3\Scripts\Pip.exe'
                    }
                }
                
                Context 'Application exists and should be present' {
                    $PipApplicationDSC.Ensure = [Ensure]::Present
                    Mock -CommandName Test-Path -MockWith {
                        $true
                    }

                    It 'Get should return ensure Present if the pip package exists.' {
                        $PipApplicationDSC.Get().ensure | Should -Be 'Present'
                    }                                        

                    It 'Get should return status Installed if the pip package exists.' {
                        $PipApplicationDSC.Get().status | Should -Be 'Installed'
                    }                    

                    It 'Test should return true if no changes are required' {
                        $PipApplicationDSC.Test() | Should -BeTrue
                    }
                }
                
                Context 'Application exists and should be absent' {
                    $PipApplicationDSC.Status = 'Installed'
                    $PipApplicationDSC.Ensure = [Ensure]::Absent
                    Mock -CommandName Test-Path -MockWith {
                        $true
                    }

                    It 'Get should return ensure Absent if the pip package should be removed.' {
                        $PipApplicationDSC.Get().ensure | Should -Be 'Absent'
                    }
                    
                    It 'Test should return false if the pip package is installed but should be absent' {
                        $PipApplicationDSC.Test() | Should -BeFalse
                    }
                    
                    It 'Set should remove the application correctly' {
                        $PipApplicationDSC.Set()
                        Assert-MockCalled -CommandName Remove-Item -Exactly -Times 1
                    }
                }
                
                Context 'Missing application which should be installed' {
                    $PipApplicationDSC.Ensure = [Ensure]::Present
                    
                    It 'Get should return status NotInstalled if the pip package is missing.' {
                        $PipApplicationDSC.Get().Status | Should -Be 'NotInstalled'
                    }
                    
                    It 'Test should return false if changes are required' {
                        $PipApplicationDSC.Test() | Should -BeFalse
                    }
                    
                    It 'Set should install the application correctly' {
                        $PipApplicationDSC.Set() 
                        Assert-MockCalled -CommandName Start-Process -Exactly -Times 1 -ParameterFilter {
                            $Argumentlist -like "*$($this.ApplicatioNName)==$($this.Version)*" -and
                            $Argumentlist -like "*--log $($PipApplicationDSC.LogPath)\$($PipApplicationDSC.ApplicatioNName)-$($PipApplicationDSC.Version).log"
                        }
                    }
                }
                
                Context 'Absent application which should be absent' {
                    $PipApplicationDSC.Ensure = [Ensure]::Absent
                    $PipApplicationDSC.ApplicationName = 'TargetApplication'
                    
                    Mock -CommandName Test-Path -MockWith {
                        $false
                    }
                    
                    It 'Get should return ensure absent if the pip package is missing.' {
                        $PipApplicationDSC.Get().Ensure | Should -Be 'Absent'
                    }
                    
                    It 'Get should return status NotInstalled if the pip package is missing.' {
                        $PipApplicationDSC.Get().Status | Should -Be 'NotInstalled'
                    }
                    
                    It 'Test should return true if changes no are required' {
                        $PipApplicationDSC.Test() | Should -BeTrue
                    }
                }
            }
        }
        Default {
            throw "Resource $_ not supported. Please add tests for $_"
        }
    }
}
