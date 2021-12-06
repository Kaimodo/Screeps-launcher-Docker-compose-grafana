    <#
.SYNOPSIS
    Create Docker-Compose-Files and Config-files for setting up screeps-launcher
.DESCRIPTION
	With this Script the needed docker-compose and other config files will be auto-generated
.PARAMETER Grafana
	If set, the Config will be set to use the Grafana Part, too.
.EXAMPLE
	PS C:\> .\createFiles.ps1 -Grafana
	Create Files with Grafana Support
.INPUTS
	System.String
.OUTPUTS
	System.String
.NOTES
	Author: Kaimodo
.LINK
	https://github.com/Kaimodo/Screeps-launcher-Docker-compose-grafana.git
#>

[CmdletBinding()]
param(

    [Parameter(	Position = 0,
      Mandatory = $false,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true
    )]
    [System.String]
    $SteamKey=$(Throw "Steam-Key required.")
)

begin {
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin"
    $TempErrAct = $ErrorActionPreference
    $ErrorActionPreference = "Stop"
    function Write-ProgressHelper {
        # thanks adam!
        # https://www.adamtheautomator.com/building-progress-bar-powershell-scripts/
        param (
            [int]$StepNumber,
            [int]$TotalS,
            [int]$Sleep,
            [string]$Message,
            [switch]$ExcludePercent
        )
        $Activity = "Doing Stuff"
        if ($ExcludePercent) {
            Write-Progress -Activity $Activity -Status $Message 
            Start-Sleep $Sleep
        } else {
            if (-not $TotalS) {
                $percentComplete = 0
            } else {
                $percentComplete = ($StepNumber / $TotalS) * 100
                Write-Verbose "Perc: $($percentComplete) | SN: $($StepNumber) | TotalS: $($TotalS)"
            }
            Write-Progress -Activity $Activity -Status $Message -PercentComplete $percentComplete 
            Start-Sleep $Sleep
        }        
    }
    $stepCounter = 0

  }

process {
    Write-Verbose "$($FunctionName): Process"
    try { 
        Write-Verbose "$($FunctionName): Process:try"
        $TS = ([System.Management.Automation.PsParser]::Tokenize((Get-Content $MyInvocation.MyCommand), [ref]$null) | Where-Object { $_.Type -eq 'Command' -and $_.Content -eq 'Write-ProgressHelper' }).Count
        Write-Host "TS: $($TS)"
        #$steps
        #$stepCounter
        Write-ProgressHelper -Message "Checking Files" -Sleep 2 -ExcludePercent
        Write-Host "Checking if Docker-Compose File already exists" -ForegroundColor Cyan
        Write-ProgressHelper -Message "Checking Files2" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        Write-ProgressHelper -Message "Checking Files2" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        Write-ProgressHelper -Message "Checking Files2" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        Write-ProgressHelper -Message "Checking Files2" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        $cfgFile = "config.yml"
        if (Test-Path -Path $cfgFile) {
            try {
                Write-Host "$($FunctionName): File: $($cfgFile) found" -ForegroundColor Green
                #Remove-Item -Path $KeyFilePath;
            } catch {
                throw $_.Exception.Message
            } 
        } else {
            try {
                $file = Split-Path -Path $cfgFile -Leaf
                $folder = Split-Path -Path $cfgFile
                Write-Host "$($FunctionName): File [$($file)] does not Exist in Folder [$($folder)]" -ForegroundColor Red
                continue
            } catch {
                throw $_.Exception.Message
            }
        }
        

        

    } catch {
        
        $ExceptionLevel = 0
        $BagroundColorErr = 'DarkRed'
        $e = $_.Exception
        $Msg = "[$($ExceptionLevel)] {$($e.Source)} $($e.Message)"
        $Msg.PadLeft($Msg.Length + (2 * $ExceptionLevel)) | Write-Host -ForegroundColor Yellow -BackgroundColor $BagroundColorErr
        $Msg.PadLeft($Msg.Length + (2 * $ExceptionLevel)) | Write-Output
    
        while ($e.InnerException) {
            $ExceptionLevel++
            if ($ExceptionLevel % 2 -eq 0) {
                $BagroundColorErr = 'DarkRed'
            }
            else {
                $BagroundColorErr = 'Black'
            }
    
            $e = $e.InnerException
    
            $Msg = "[$($ExceptionLevel)] {$($e.Source)} $($e.Message)"
            $Msg.PadLeft($Msg.Length + (2 * $ExceptionLevel)) | Write-Host -ForegroundColor Yellow -BackgroundColor $BagroundColorErr
            $Msg.PadLeft($Msg.Length + (2 * $ExceptionLevel)) | Write-Output
        }
    }
}
end {
    Write-Verbose "$($FunctionName): End."
    $ErrorActionPreference = $TempErrAct
}