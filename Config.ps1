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
