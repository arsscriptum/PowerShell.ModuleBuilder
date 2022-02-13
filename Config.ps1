<#
#̷\   ⼕龱ᗪ㠪⼕闩丂ㄒ龱尺 ᗪ㠪ᐯ㠪㇄龱尸爪㠪𝓝ㄒ
#̷\   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇨​​​​​🇴​​​​​🇩​​​​​🇪​​​​​🇨​​​​​🇦​​​​​🇸​​​​​🇹​​​​​🇴​​​​​🇷​​​​​@🇮​​​​​🇨​​​​​🇱​​​​​🇴​​​​​🇺​​​​​🇩​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
##
##  Quebec City, Canada, MMXXI
#>

#===============================================================================
# Dependencies
#===============================================================================

# $ModuleDependencies = @( 'CodeCastor.PowerShell.Core' )
$ModuleDependencies = @( )
$EnvironmentVariable = @( 'OrganizationHKCU', 'OrganizationHKLM' )
$FunctionDependencies = @( 'Show-ExceptionDetails','Get-ScriptDirectory' ,
                "Import-CustomModule",
                "Invoke-ValidateDependencies",
                "Approve-FunctionNames",
                "Get-ExportedAliassDecl",
                "Get-AliasList",
                "Select-AliasName",
                "Select-FunctionName",
                "Install-ModuleToDirectory",
                "Get-ExportedFunctionsDecl",
                "Get-AssembliesDecl",
                "Get-FunctionList",
                "Get-ModulePath",
                "Get-DefaultModulePath",
                "Get-ExportedFilesDecl",
                "Get-WritableModulePath",

                # --- Exported Functions from Parser.ps1 ---
               # "Remove-CommentsFromScriptBlock",

                # --- Exported Functions from Process.ps1 ---
                "Invoke-Process")

    $TotalErrors = 0

    $ScriptMyInvocation = $Script:MyInvocation.MyCommand.Path
    $CurrentScriptName = $Script:MyInvocation.MyCommand.Name
    $PSScriptRootValue = 'null' ; if($PSScriptRoot) { $PSScriptRootValue = $PSScriptRoot}
    $ModuleName = (Get-Item $PSScriptRootValue).Name
    Write-Host "===============================================================================" -f DarkRed
    Write-Host "MODULE $ModuleName BUILD CONFIGURATION AND VALIDATION" -f DarkYellow;
    Write-Host "===============================================================================" -f DarkRed    

    Write-Host "[CONFIG] " -f Blue -NoNewLine
    Write-Host "CHECKING ENVIRONMENT VARIABLE.."
    $EnvironmentVariable.ForEach({
        $EnvVar=$_
        $Var = [System.Environment]::GetEnvironmentVariable($EnvVar,[System.EnvironmentVariableTarget]::User)
        if($Var -eq $null){
            throw "ERROR: MISSING $EnvVar Environment Variable"
        }else{
            Write-Host "`t`t[OK]`t" -f DarkGreen -NoNewLine
            Write-Host "$EnvVar"
        }
    })
     Write-Host "[CONFIG] " -f Blue -NoNewLine
    Write-Host "CHECKING CORE MODULE DEPENDENCIES..."
    $ModuleName='PowerShell.Core'
    $ModPtr = Get-Module "$ModuleName" -ErrorAction Stop    
    if($ModPtr -eq $null){
            Write-Host "`t`t[MIS]`t" -f DarkRed -NoNewLine
            Write-Host "$ModuleName"  -f DarkYellow  
            Write-Host "`t`t[INC]`t" -f DarkCyan -NoNewLine
            Write-Host "Including files"  -f DarkGray
            . "$ENV:PSModCore\src\Exception.ps1"   
            . "$ENV:PSModCore\src\Module.ps1"
            . "$ENV:PSModCore\src\Miscellaneous.ps1"
            . "$ENV:PSModCore\src\Script.ps1"
            . "$ENV:PSModCore\src\Process.ps1"            

    }

    Write-Host "[CONFIG] " -f Blue -NoNewLine
    Write-Host "CHECKING MODULE DEPENDENCIES..."
    $ModuleDependencies.ForEach({
        $ModuleName=$_
    
        import-module $ModuleName -Force
        $ModPtr = Get-Module "$ModuleName" -ErrorAction Stop    
        
        
        if($ModPtr -eq $null){
            Write-Host "`t`t[MIS]`t" -f DarkRed -NoNewLine
            Write-Host "$ModuleName"  -f DarkYellow  
            $TotalErrors++
        }else{
            Write-Host "`t`t[OK]`t" -f DarkGreen -NoNewLine
            Write-Host "$ModuleName"
        }
    })

    
    Write-Host "[CONFIG] " -f Blue -NoNewLine
    Write-Host "CHECKING FUNCTION DEPENDENCIES..."
    $FunctionDependencies.ForEach({
        $Function=$_
        $FunctionPtr = Get-Command "$Function" -ErrorAction Ignore
        if($FunctionPtr -eq $null){
           
            Write-Host "`t`t[MIS]`t" -f DarkRed -NoNewLine
            Write-Host "$Function MISSING"  -f DarkYellow  
            $TotalErrors++
        }else{
            Write-Host "`t`t[OK]`t" -f DarkGreen -NoNewLine
            Write-Host "$Function"
        }
    })

return $TotalErrors

# SIG # Begin signature block
# MIIFxAYJKoZIhvcNAQcCoIIFtTCCBbECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUB/GuyDL+px+mHRVGHbdp+qk9
# EmKgggNNMIIDSTCCAjWgAwIBAgIQmkSKRKW8Cb1IhBWj4NDm0TAJBgUrDgMCHQUA
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
# MQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU60JMM6YCNJSlPObYmDvv
# fd1QpGYwDQYJKoZIhvcNAQEBBQAEggEAO+p9MT8ADDLFvK0HlkhK4qbZbRYkkvQw
# orhksVSE+Mm2E21SUwPYbie/RYaGwajL4njKxIi6Lcj2pbIXEA+5niGQ/pZ4VXjt
# h232GUxRiXTKksFqhhWs2+1rmy84WNbdax72ZUpgi3QOXu4jeXXP35FAaZABhqhS
# d3b290MtiLsUCBSsq3gJZ1w4KcD1lGgOcuHrzAzgZrcv17t6V7EjP7O/BgRjg1TZ
# GH9mlf8O9unXnXbKc5vX3ldxnvwEGjyO318VMpGhZqaWNUjm60jEzZy40m+NrMFu
# cDrknDY7ntl+p1akB/B+H4x4gGisNlFNY7LHR2lUl74M7APp32GDMQ==
# SIG # End signature block
