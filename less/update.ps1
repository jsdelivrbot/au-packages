import-module au

$releases = 'http://guysalias.tk/misc/less/'

function global:au_SearchReplace {
    @{
        ".\legal\VERIFICATION.txt" = @{
          "(?i)(\s+x32:).*"      = "`${1} $($Latest.URL32)"
          "(?i)(checksum32:).*"  = "`${1} $($Latest.Checksum32)"
        }

        "$($Latest.PackageName).nuspec" = @{
            "(\<releaseNotes\>).*?(\</releaseNotes\>)" = "`${1}$($Latest.ReleaseNotes)`$2"
        }
    }
}

function global:au_BeforeUpdate {    
    set-alias 7z $Env:chocolateyInstall\tools\7z.exe

    $lessdir = "$PSScriptRoot\less-*-win*"
    rm $lessdir -Recurse -Force -ea ignore

    iwr $Latest.URL32 -OutFile "$PSScriptRoot\less.7z"
    7z x $PSScriptRoot\less.7z
    $Latest.Checksum32 = Get-FileHash $PSScriptRoot\less.7z | % Hash

    rm $PSScriptRoot\tools -Recurse -Force -ea 0
    mkdir $PSScriptRoot\tools | Out-Null
    mv $lessdir\* $PSScriptRoot\tools -Force
    rm $lessdir -Recurse -Force -ea ignore
    rm $PSScriptRoot\less.7z -ea ignore
}

function global:au_GetLatest {
    $download_page = Invoke-WebRequest -Uri $releases -UseBasicParsing

    $re  = 'less-(.+)win(.+)\.7z$'
    $url = $download_page.links | ? href -match $re | % href | sort | select -Last 1
    $version = $url -split '-' | select -Index 1
    @{
       URL32   = $releases + $url
       Version = "$($version / 100)" #must use string interpollation here to force the invariant rather than the current culture
       ReleaseNotes = "http://www.greenwoodsoftware.com/less/news.$version.html"
    }
}

try {
    update -ChecksumFor none
} catch {
    $ignore = 'Unable to connect to the remote server'
    if ($_ -match $ignore) { Write-Host $ignore; 'ignore' }  else { throw $_ }
}
