<#
  ╓──────────────────────────────────────────────────────────────────────────────────────
  ║   PowerShell Signature Functions
  ║
  ║   Guillaume Plante <guillaumeplante.qc@gmail.com>
  ║   https://github.com/arsscriptum/
  ╙──────────────────────────────────────────────────────────────────────────────────────
 #>

#===============================================================================
# SignatureProperties
#===============================================================================

class SignatureProperties
{
    [string]$ValidCertificate = '5784C51A025A7E42DD96B95D8F54AA240BE4C98E'
}

function Get-LocalSigningCert{
    <#
    .SYNOPSIS
        Get signing certificate
    .LINK
        https://github.com/arsscriptum/PowerShell.Sandbox/blob/main/Signing/Signing.ps1
    #>    
    
    $SignProps = [SignatureProperties]::new()
    $Instance=gci Cert:\CurrentUser\My -CodeSigningCert | where Thumbprint -eq "$($SignProps.ValidCertificate)"
    return $Instance
}

function Add-Signature{
    <#
    .SYNOPSIS
        Sign a script
    .DESCRIPTION
        Sign a script using a self-signed certificate
    .PARAMETER Path
        The Path of the script to sign
    .EXAMPLE
         Add-Signature -Path .\helloworld.ps1
    .LINK
        https://github.com/arsscriptum/PowerShell.Sandbox/blob/main/Signing/Signing.ps1
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    try{
        $Ok = $False
        $ExceptMsg = ''
        $cert = Get-LocalSigningCert
        if($cert -eq $Null){ throw "Cannot find signing Certificate" }
        Write-Host "✅ Get Signing Certificate"
        $Res = Set-AuthenticodeSignature $Path -Certificate $cert 
        $Status = $Res.Status
        $StatusMessage = $Res.StatusMessage
        Write-Host "✅ Set-AuthenticodeSignature on $Path. Status: $Status, $StatusMessage"
        $Ok = $True
    }catch {
        [System.Management.Automation.ErrorRecord]$Record = $_
        $formatstring = "[ERROR] Signing {0} : {1}"
        $fields = $Path,$Record.FullyQualifiedErrorId
        $ExceptMsg=($formatstring -f $fields)
        $Ok = $False
        
    }
    if (-not $Ok) {
        $Exception = [System.InvalidOperationException]::new("$ExceptMsg")
        throw $Exception
    }
}

function Check-Signature{
    <#
    .SYNOPSIS
        Validate a script signature
    .PARAMETER Path
        The Path of the script to validate
    .EXAMPLE
         Check-Signature -Path .\helloworld.ps1
    .LINK
        https://github.com/arsscriptum/PowerShell.Sandbox/blob/main/Signing/Signing.ps1
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )    
    try{
        $Ok = $False
        $ExceptMsg = ''        

        $cert = Get-LocalSigningCert
        if($cert -eq $Null){ throw "Cannot find signing Certificate" }
        Write-Host "✅ Get Signing Certificate"
        $Res = Get-AuthenticodeSignature $Path 
        $Status = $Res.Status
        $StatusMessage = $Res.StatusMessage
        $SignerCertificate = $Res.SignerCertificate
        if($Status -ne 'Valid'){ throw "Script not signed or invalid signature!" }
        if($cert -ne $SignerCertificate){ throw "Script signed with wrong certificate ($SignerCertificate)" }
        Write-Host "✅ Signature $Path. Status: $Status, $StatusMessage"
        $Ok = $True
    }catch {
        [System.Management.Automation.ErrorRecord]$Record = $_
        $formatstring = "[ERROR] Verification failed for {0} : {1}"
        $fields = $Path,$Record.FullyQualifiedErrorId
        $ExceptMsg=($formatstring -f $fields)
        $Ok = $False
        
    }
    if (-not $Ok) {
        $Exception = [System.InvalidOperationException]::new("$ExceptMsg")
        throw $Exception
    }
}


# SIG # Begin signature block
# MIIFxAYJKoZIhvcNAQcCoIIFtTCCBbECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUMFQ/kHe1IMGvQksqDt74A9ia
# IP6gggNNMIIDSTCCAjWgAwIBAgIQmkSKRKW8Cb1IhBWj4NDm0TAJBgUrDgMCHQUA
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
# MQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUvrZJY2vk8YR6732elpDR
# T5ZTuNEwDQYJKoZIhvcNAQEBBQAEggEAF0JxjVB0Vtuty8NUlGh+ZHkT31hhNU8t
# zZIuvTGs8xxeO0aVUCUxDFNlsOfoO3g22dCK4TumDrAeZfHGh9sq7c4NKtLda2rT
# oalRn3UOkialwrAjYfJ2Z54jMNYfTNv66LV4WV+eTStku66KWxnGPU2Ko/Of6VDW
# UKqAIdMcZ8Yz2/ARDBoqF8VMbLe75j8R5jA3DU8sbLsKarkLzS19LtNbJuTBlm4T
# 3MqSYWxh6Fi3t0VcVkvB0a+ALLlWblsXsCWN22kmj8vnmY3tWBnDCi8nYWaoMB7b
# YXyFhQPy92c6BEbN0fzS/DrtLx4V4fIsZx4QfpZmpaKbWUqH62NJmg==
# SIG # End signature block
