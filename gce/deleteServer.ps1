<#
.SYNOPSIS
    Delete VM and CleanUp on GoogleComputeEngine (GCE)
.DESCRIPTION
	Script to Delete a VM-Instance on GCE
.PARAMETER ProjectName
	The Name of the GCE Project
.PARAMETER Zone
	The Zone of the GCE Project
.EXAMPLE
	PS C:\> .\deleteServer.ps1 -ProjectName "Screeps" -Zone "europe-west3-c"
	Deletes The Project with the given Values
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
        Mandatory = $true,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [System.String]
    $ProjectName = $(Throw "ProjectName required."),
    
    [Parameter(	Position = 1,
    Mandatory = $true,
    ValueFromPipeline = $true,
    ValueFromPipelineByPropertyName = $true
    )]
    [System.String]
    $Zone = $(Throw "Zone required.")

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
        $Activity = "Deleting VM and Resources"
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
        Write-Verbose "$($FunctionName): Process:catch"  
        $TS = ([System.Management.Automation.PsParser]::Tokenize((Get-Content $MyInvocation.MyCommand), [ref]$null) | Where-Object { $_.Type -eq 'Command' -and $_.Content -eq 'Write-ProgressHelper' }).Count

        Write-ProgressHelper -Message "Delete VM Instance in Project $($ProjectName)" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS 
        $InstName = $ProjectName + "-instance"
        Remove-GceInstance -Project $ProjectName `
            -Zone $Zone -Name $InstName;
        
        Write-ProgressHelper -Message "$($ProjectName)|Delete Firewall-Rule for Port 22" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS         
        $FWName = $ProjectName + "-FW-22"
        Remove-GceFirewall $FWName -Project $ProjectName;

        Write-ProgressHelper -Message "$($ProjectName)|Delete Firewall-Rule for Port 21025" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS         
        $FWName = $ProjectName + "-FW-21025"
        Remove-GceFirewall $FWName -Project $ProjectName;

        Write-ProgressHelper -Message "$($ProjectName)|Delete Firewall-Rule for Port 21026" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS         
        $FWName = $ProjectName + "-FW-21026"
        Remove-GceFirewall $FWName -Project $ProjectName;

        Write-ProgressHelper -Message "$($ProjectName)|Delete Firewall-Rule for Port 3000" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS         
        $FWName = $ProjectName + "-FW-3000"
        Remove-GceFirewall $FWName -Project $ProjectName;
        
        Write-ProgressHelper -Message "$($ProjectName)|Delete the custom GCP network" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS         
        $NWName = $ProjectName + "-Network"
        Remove-GceNetwork -Name $NWName -Project $ProjectName;

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