


#===============================================================================
# Builders
#===============================================================================

function Submit-AllModules{
    [CmdletBinding(SupportsShouldProcess)]
    Param()     
    pushd "$ENV:PSModDev"
    $AllMods = (gci . -Directory).Fullname ;  $AllMods | % { $m=$_;pushd $m;write-host -f DarkRed "`nCOMMIT EVERYTHING IN $m`n" ; if($Compile){make -i -d -Documentation ; }; git add *; git commit -a -m 'latest' ; git push ; popd ; }
    popd
}

function Import-AllModules{
    pushd "$ENV:PSModDev"
    $Tmp=(New-TemporaryFile).Fullname
    $AllMods = (gci . -Directory).Name ;  $AllMods | % { 
        try{
            $m=$_;
            write-host -n -f DarkCyan "[$m]`t`t" ;
            import-module $m -Force -ErrorAction Stop -DisableNameChecking 2> $Tmp
            write-host -f DarkGreen "OK" ;
        }
        catch{
            write-host -f DarkRed "ERROR $_" ;
        }
     }

    popd
}

function Build-AllModules()
{
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        [Parameter(Mandatory=$false,ValueFromPipeline=$true, HelpMessage="commit to git") ]
        [switch]$Commit
    ) 
    pushd "$ENV:PSModDev"
    $BuildMod = [System.Collections.ArrayList]::new()
    $AllMods = @(gci . -Directory).Fullname ; 
    ForEach($mod in $AllMods){
        $Null=$BuildMod.Add($mod)
    }
    $modcount = $BuildMod.Count
    if($modcount -gt 0){
        Write-Host -f DarkYellow "Building those modules: " 
        $BuildMod | % { $m=$_; $nn = (Get-Item $m).Name ;Write-Host " ===> $nn" -f DarkYellow -n; if($Commit){Write-Host " (also git commit) " -f DarkRed; }else{Write-Host "";};  } ; sleep 3 ;$BuildMod | % { $m=$_;pushd $m; make -i -d ; if($Commit){push; }; popd ;} ; popd ;     
    }
}

function Build-Module{
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true, HelpMessage="Full repository Url https or ssh") ]
        [String]$Name,
        [switch]$Commit
    ) 
    pushd "$ENV:PSModDev"
    $BuildMod = [System.Collections.ArrayList]::new()
    $AllMods = @(gci . -Directory).Fullname ; 
    ForEach($mod in $AllMods){
        if($mod -match $Name){
            Write-Host -n "Found " -f DarkRed ;
            Write-Host "$mod" -f DarkYellow ;
            $Null=$BuildMod.Add($mod)
        }
    }
    $modcount = $BuildMod.Count
    if($modcount -gt 0){
        Write-Host "Building those modules: " -f DarkYellow ;
        $BuildMod | % { $m=$_; $nn = (Get-Item $m).Name ;Write-Host " ===> $nn" -f DarkYellow -n; if($Commit){Write-Host " (also git commit) " -f DarkRed; }else{Write-Host "";};  } ; sleep 3 ;$BuildMod | % { $m=$_;pushd $m; make -i -d ; if($Commit){push; }; popd ;} ; popd ;     
    }
    
}