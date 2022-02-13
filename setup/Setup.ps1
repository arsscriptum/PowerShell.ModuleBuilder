<#
#̷\   ⼕龱ᗪ㠪⼕闩丂ㄒ龱尺 ᗪ㠪ᐯ㠪㇄龱尸爪㠪𝓝ㄒ
#̷\   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇨​​​​​🇴​​​​​🇩​​​​​🇪​​​​​🇨​​​​​🇦​​​​​🇸​​​​​🇹​​​​​🇴​​​​​🇷​​​​​@🇮​​​​​🇨​​​​​🇱​​​​​🇴​​​​​🇺​​​​​🇩​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>

[CmdletBinding(SupportsShouldProcess)]
param (
      [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
      [switch]$Quiet,
      [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
      [switch]$Alias
    )



function Get-ModuleBuilderRoot{

    if($ENV:PSModuleBuilder -ne $Null){
        if(Test-Path $ENV:PSModuleBuilder -PathType Container){
            return $ENV:PSModuleBuilder
        }
    }else{
        $TmpPath = (Get-Item $Profile).DirectoryName
        $TmpPath = Join-Path $TmpPath 'Projects\PowerShell.ModuleBuilder'
        if(Test-Path $TmpPath -PathType Container){
            $ModuleBuilder = $TmpPath
            return $ModuleBuilder
        }

    }
    $mydocuments = [environment]::getfolderpath("mydocuments") 
    $ModuleBuilder = Join-Path $mydocuments 'PowerShell\Projects\PowerShell.ModuleBuilder'
    return $ModuleBuilder
}


function Get-PSModuleDevelopmentRoot{

    if($ENV:PSModuleDevelopmentRoot -ne $Null){
        if(Test-Path $ENV:PSModuleDevelopmentRoot -PathType Container){
            $PSModuleDevelopmentRoot = $ENV:PSModuleDevelopmentRoot
            return $PSModuleDevelopmentRoot
        }
    }else{
        $TmpPath = (Get-Item $Profile).DirectoryName
        $TmpPath = Join-Path $TmpPath 'Module-Development'
        if(Test-Path $TmpPath -PathType Container){
            $PSModuleDevelopmentRoot = $TmpPath
            return $PSModuleDevelopmentRoot
        }

    }
    $mydocuments = [environment]::getfolderpath("mydocuments") 
    $PSModuleDevelopmentRoot = Join-Path $mydocuments 'PowerShell\Module-Development'
    return $PSModuleDevelopmentRoot
}


#===============================================================================
# OrganizationHKCU
#===============================================================================
if( ($ENV:OrganizationHKCU -eq $null) -Or ($ENV:OrganizationHKCU -eq '') )
{
    Write-Host "===============================================================================" -f DarkRed    
    Write-Host "A required environment variable needs to be setup (user scope)     `t" -NoNewLine -f DarkYellow ; Write-Host "$Script:OrganizationHKCU" -f Gray 
    $OrgIdentifier = "Development-" + "$ENV:USERNAME"
    $OrganizationHKCU = "HKCU:\Software\" + "$OrgIdentifier"

    [Environment]::SetEnvironmentVariable('OrganizationHKCU',$OrganizationHKCU,"User")

    Write-Host "Setting OrganizationHKCU --> $OrganizationHKCU [User]"  -ForegroundColor Yellow
    $Null = New-Item -Path "$OrganizationHKCU" -Force -ErrorAction Ignore

    $Cmd = Get-Command "RefreshEnv.cmd"
    if($Cmd){
        $RefreshEnv = $Cmd.Source
        &"$RefreshEnv"
    }

    $ENV:OrganizationHKCU = "$OrganizationHKCU"

}

$Name = $script:MyInvocation.MyCommand.Name
$i = $Name.IndexOf('.')
$Script:CurrentScript = $Name.SubString(0, $i)
$Script:CurrPath=$PSScriptRoot #Split-Path $script:MyInvocation.MyCommand.Path


#===============================================================================
# Script Variables
#===============================================================================
$Script:CurrentRunningScript           = $Script:CurrentScript
$Script:Time                           = Get-Date
$Script:Date                           = $Time.GetDateTimeFormats()[19]

Write-Host "===============================================================================" -f DarkRed
Write-Host "CONFIGURATION of DEVELOPMENT ENVIRONMENT for MODULE BUILDER" -f DarkYellow;
Write-Host "===============================================================================" -f DarkRed    
Write-Host "Current Path     `t" -NoNewLine -f DarkYellow ; Write-Host "$Script:CurrPath" -f Gray 
Write-Host "Current Script   `t" -NoNewLine -f DarkYellow;  Write-Host "$Script:CurrentScript" -f Gray 

Write-Host "Setting PSModuleBuilder to `t" -NoNewLine -f DarkYellow;  Write-Host "$Script:CurrPath" -f Gray 
[Environment]::SetEnvironmentVariable('PSModuleBuilder',$Script:CurrPath,"User")


#===============================================================================
# ModuleBuilderRoot Variable
#===============================================================================





$Name = (Get-Item $PSScriptRoot).Name
$DisplayName = 'PowerShell.ModuleBuilder'
$RegistryPath = "$ENV:OrganizationHKCU\$Name"
 Write-Host "[$DisplayName] " -f Blue -NonewLin
 Write-Host " $RegistryPath" -f White

$ModuleBuilderPath = Get-ModuleBuilderRoot
$ModuleDevelopmentPath =  Get-PSModuleDevelopmentRoot
$BuildScript = Join-Path $ModuleBuilderPath 'Build.ps1'
$BuildModuleScript = Join-Path $ModuleBuilderPath 'Build-Module.ps1'

try{
    if($Quiet -eq $False){
        Write-Host "[$DisplayName] " -f Blue -NonewLine
        Write-Host "configuring registry values" -f White
    }

    Remove-Item $RegistryPath -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
    New-Item $RegistryPath -Force  -ErrorAction SilentlyContinue | Out-Null
    $Added_BuildScriptPath =(New-ItemProperty $RegistryPath -Name 'BuildScriptPath' -Value  "$BuildScript"  -ErrorAction SilentlyContinue).BuildScriptPath
    #if($Added_BuildScriptPath -ne $BuildScriptPath) { throw "BAD REGISTRY VALUE $Added_BuildScriptPath"; }
    $Added_ModuleBuilderPath = (New-ItemProperty $RegistryPath -Name 'ModuleBuilderPath' -Value  "$ModuleBuilderPath"  -ErrorAction SilentlyContinue).ModuleBuilderPath
    #if($Added_ModuleBuilderPath -ne $ModuleBuilderPath) { throw "BAD REGISTRY VALUE $Added_ModuleBuilderPath"; }    
    $Added_BuildModuleScript = (New-ItemProperty $RegistryPath -Name 'BuildModuleScript' -Value  "$BuildModuleScript"  -ErrorAction SilentlyContinue ).BuildModuleScript
    #if($Added_BuildModuleScript -ne $BuildModuleScript) { throw "BAD REGISTRY VALUE $Added_BuildModuleScript"; }
    $Added_ModuleDevelopmentPath = (New-ItemProperty $RegistryPath -Name 'ModuleDevelopmentPath' -Value  "$ModuleDevelopmentPath"  -ErrorAction SilentlyContinue).ModuleDevelopmentPath
    #if($Added_ModuleDevelopmentPath -ne $ModuleDevelopmentPath) { throw "BAD REGISTRY VALUE $Added_ModuleDevelopmentPath"; }
}catch{
    Write-Host "[error] " -f DarkRed -NonewLine
    Write-Host "$_" -f DarkYellow    
}


if($Quiet -eq $False){
    Write-Host "[$DisplayName] " -f DarkRed -NonewLine
    Write-Host " BuildScriptPath`t==>`t$BuildScript" -f DarkYellow
    Write-Host "[$DisplayName] " -f DarkRed -NonewLine
    Write-Host "  ModuleBuilder`t==>`t$ModuleBuilderPath" -f DarkYellow
    Write-Host "[$DisplayName] " -f DarkRed -NonewLine
    Write-Host " DevelopmentPath`t==>`t$ModuleDevelopmentPath" -f DarkYellow
}


if($Alias){
    if($Quiet -eq $False){
        Write-Host "[$DisplayName] "  -f Blue -NonewLine
        Write-Host "configuring alias values" -f White    
    }
    Remove-Alias -Name make -Force | Out-null
    if(Test-Path -Path $BuildScript -PathType Leaf){
        if($Quiet -eq $False){
            Write-Host "[$DisplayName] " -f DarkRed -NonewLine
            Write-Host "`tmake`t`t==>`t$BuildScript" -f DarkYellow
        }
        New-Alias -Name make -Value "$BuildScript" -Description 'Build a module' -Scope Global
    }
    Remove-Alias -Name makeall -Force | Out-null
    if(Test-Path -Path $BuildModuleScript -PathType Leaf){
        if($Quiet -eq $False){
            Write-Host "[$DisplayName] " -f DarkRed -NonewLine
            Write-Host "`tmakeall`t`t==>`t$BuildModuleScript" -f DarkYellow
        }
        New-Alias -Name makeall -Value "$BuildModuleScript" -Description 'Build a module' -Scope Global
    }
    if($Quiet -eq $False){
        Write-Host "`n`n[$DisplayName] " -f DarkRed -NonewLine
        Write-Host " To build a module, type 'make' or 'makeall'. Optionally Use -Import -Deploy" -f DarkYellow 
    }
}
# SIG # Begin signature block
# MIIFxAYJKoZIhvcNAQcCoIIFtTCCBbECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUuKXker9qZmxuYZMOpUg6f+zC
# XuagggNNMIIDSTCCAjWgAwIBAgIQmkSKRKW8Cb1IhBWj4NDm0TAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0yMjAyMDkyMzI4NDRaFw0zOTEyMzEyMzU5NTlaMCUxIzAhBgNVBAMTGkFyc1Nj
# cmlwdHVtIFBvd2VyU2hlbGwgQ1NDMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
# CgKCAQEA60ec8x1ehhllMQ4t+AX05JLoCa90P7LIqhn6Zcqr+kvLSYYp3sOJ3oVy
# hv0wUFZUIAJIahv5lS1aSY39CCNN+w47aKGI9uLTDmw22JmsanE9w4vrqKLwqp2K
# +jPn2tj5OFVilNbikqpbH5bbUINnKCDRPnBld1D+xoQs/iGKod3xhYuIdYze2Edr
# 5WWTKvTIEqcEobsuT/VlfglPxJW4MbHXRn16jS+KN3EFNHgKp4e1Px0bhVQvIb9V
# 3ODwC2drbaJ+f5PXkD1lX28VCQDhoAOjr02HUuipVedhjubfCmM33+LRoD7u6aEl
# KUUnbOnC3gVVIGcCXWsrgyvyjqM2WQIDAQABo3YwdDATBgNVHSUEDDAKBggrBgEF
# BQcDAzBdBgNVHQEEVjBUgBD8gBzCH4SdVIksYQ0DovzKoS4wLDEqMCgGA1UEAxMh
# UG93ZXJTaGVsbCBMb2NhbCBDZXJ0aWZpY2F0ZSBSb290ghABvvi0sAAYvk29NHWg
# Q1DUMAkGBSsOAwIdBQADggEBAI8+KceC8Pk+lL3s/ZY1v1ZO6jj9cKMYlMJqT0yT
# 3WEXZdb7MJ5gkDrWw1FoTg0pqz7m8l6RSWL74sFDeAUaOQEi/axV13vJ12sQm6Me
# 3QZHiiPzr/pSQ98qcDp9jR8iZorHZ5163TZue1cW8ZawZRhhtHJfD0Sy64kcmNN/
# 56TCroA75XdrSGjjg+gGevg0LoZg2jpYYhLipOFpWzAJqk/zt0K9xHRuoBUpvCze
# yrR9MljczZV0NWl3oVDu+pNQx1ALBt9h8YpikYHYrl8R5xt3rh9BuonabUZsTaw+
# xzzT9U9JMxNv05QeJHCgdCN3lobObv0IA6e/xTHkdlXTsdgxggHhMIIB3QIBATBA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdAIQ
# mkSKRKW8Cb1IhBWj4NDm0TAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAig
# AoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgEL
# MQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUnuVy9301eyGV7rlVMzoO
# ZOMSfUUwDQYJKoZIhvcNAQEBBQAEggEAVP968QRF0LPPpwa4dUouFayQi2wpOU0R
# PUjTV94xxs7OqwAlWf708+86IlcHCiMsBlNuo4fWasMXsC8b5YjqmyycIOXAqb3X
# hdAaNam4+vbKENYVAjC6JGrRXiuST3QLhGjcG1fujkwGg6s+zmVGSfHpRlxW++xj
# SkfbMR2ugTmfyyBRF8yQn4NJqlKkOZB9AfvKy+4YE+SaZcMz47C9l0dr/KhcUEL3
# l7pOMS5F5PJwtahEBU4UmJSezubqPmzUMlOkMq1p7bdDbWMxyXlt3lWKyMTZZuRx
# Og8uu6PQY7LdgvIp29dPGmEemkn+17qoWnbNqT1hhWmrPTTjlrUosA==
# SIG # End signature block
