<#
#ฬท๐   ๐๐ก๐ข ๐ข๐๐ก๐๐๐ฃ๐ค๐
#ฬท๐   ๐ตโโโโโ๐ดโโโโโ๐ผโโโโโ๐ชโโโโโ๐ทโโโโโ๐ธโโโโโ๐ญโโโโโ๐ชโโโโโ๐ฑโโโโโ๐ฑโโโโโ ๐ธโโโโโ๐จโโโโโ๐ทโโโโโ๐ฎโโโโโ๐ตโโโโโ๐นโโโโโ ๐งโโโโโ๐พโโโโโ ๐ฌโโโโโ๐บโโโโโ๐ฎโโโโโ๐ฑโโโโโ๐ฑโโโโโ๐ฆโโโโโ๐บโโโโโ๐ฒโโโโโ๐ชโโโโโ๐ตโโโโโ๐ฑโโโโโ๐ฆโโโโโ๐ณโโโโโ๐นโโโโโ๐ชโโโโโ.๐ถโโโโโ๐จโโโโโ@๐ฌโโโโโ๐ฒโโโโโ๐ฆโโโโโ๐ฎโโโโโ๐ฑโโโโโ.๐จโโโโโ๐ดโโโโโ๐ฒโโโโโ
#>



function New-ErrorRecord
{
<#
    .SYNOPSIS
        Returns an ErrorRecord object for use by $PSCmdlet.ThrowTerminatingError

    .DESCRIPTION
        Returns an ErrorRecord object for use by $PSCmdlet.ThrowTerminatingError

    .PARAMETER ErrorMessage
        The message that describes the error

    .PARAMETER ErrorId
        The Id to be used to construct the FullyQualifiedErrorId property of the error record.

    .PARAMETER ErrorCategory
        This is the ErrorCategory which best describes the error.

    .PARAMETER TargetObject
        This is the object against which the cmdlet was operating when the error occurred. This is optional.

    .OUTPUTS
        System.Management.Automation.ErrorRecord

    .NOTES
        ErrorRecord Class - https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.errorrecord
        Exception Class - https://docs.microsoft.com/en-us/dotnet/api/system.exception
        Cmdlet.ThrowTerminationError - https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.cmdlet.throwterminatingerror
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'This function is non state changing.')]
    [OutputType([System.Management.Automation.ErrorRecord])]
    param(
        [Parameter(Mandatory)]
        [System.String] $ErrorMessage,

        [System.String] $ErrorId,

        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorCategory] $ErrorCategory,

        [System.Management.Automation.PSObject] $TargetObject
    )

    $exception = New-Object -TypeName System.Exception -ArgumentList $ErrorMessage
    $errorRecordArgumentList = $exception, $ErrorId, $ErrorCategory, $TargetObject
    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $errorRecordArgumentList

    return $errorRecord
}




#===============================================================================
# Helpers
#===============================================================================


function Show-ExceptionDetails{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]$Record,
        [Parameter(Mandatory=$false)]
        [switch]$ShowStack
    )       
    $formatstring = "{0}`n{1}"
    $fields = $Record.FullyQualifiedErrorId,$Record.Exception.ToString()
    $ExceptMsg=($formatstring -f $fields)
    $Stack=$Record.ScriptStackTrace
    Write-Host "`n[ERROR] -> " -NoNewLine -ForegroundColor DarkRed; 
    Write-Host "$ExceptMsg`n`n" -ForegroundColor DarkYellow
    if($ShowStack){
        Write-Host "--stack begin--" -ForegroundColor DarkGreen
        Write-Host "$Stack" -ForegroundColor Gray  
        Write-Host "--stack end--`n" -ForegroundColor DarkGreen       
    }
}  
