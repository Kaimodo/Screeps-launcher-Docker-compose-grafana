<#
.SYNOPSIS
    Create VM on GoogleComputeEngine (GCE)
.DESCRIPTION
	Script to Create and Configure a VM-Instance on GCE
.PARAMETER ProjectName
	The Name of the GCE Project
.PARAMETER Zone
	The Zone of the GCE Project
.PARAMETER MachineType
	The Type of the ec2 Machine
.EXAMPLE
	PS C:\> .\createServer.ps1 -ProjectName "Screeps" -Zone "europe-west3-c" -MachineType "e2-small"
	Creates The Project with the given Values
.EXAMPLE
	PS C:\> .\createServer.ps1 -ProjectName "Screeps" -Zone "europe-west3-c"
	Creates The Project with the given Values and the Standard Machine Type
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
    $Zone = $(Throw "Zone required."),

    [Parameter(	Position = 2,
        Mandatory = $false,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [System.String]
    $MachineType = "e2-micro"
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
        Write-ProgressHelper -Message "Create VM Instance in Project $($ProjectName)" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS 
        
        Write-ProgressHelper -Message "$($ProjectName)|Creates a new Google Compute Engine custom network" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS         
        $NWName = $ProjectName + "-Network"
        $MyGCPNetwork = New-GceNetwork -Name $NWName `
            -Project $ProjectName -AutoSubnet;

        Write-ProgressHelper -Message "$($ProjectName)|Add a new Firewall rule for Port 22(ssh) connection" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS         
        $FWName = $ProjectName + "-FW-22"
        $MyGCPFireWall = New-GceFirewallProtocol tcp -Port 22 | Add-GceFirewall `
            -Name $FWName -Project $ProjectName -Network $MyGCPNetwork.SelfLink;

        Write-ProgressHelper -Message "$($ProjectName)|Add a new Firewall rule for Port 21025(Screeps-Server) connection" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS         
        $FWName = $ProjectName + "-FW-21025"
        $MyGCPFireWall = New-GceFirewallProtocol tcp -Port 21025 | Add-GceFirewall `
            -Name $FWName -Project $ProjectName -Network $MyGCPNetwork.SelfLink;

        Write-ProgressHelper -Message "$($ProjectName)|Add a new Firewall rule for Port 21026(Screeps-Server-CLI) connection" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS         
        $FWName = $ProjectName + "-FW-21026"
        $MyGCPFireWall = New-GceFirewallProtocol tcp -Port 21026 | Add-GceFirewall `
            -Name $FWName -Project $ProjectName -Network $MyGCPNetwork.SelfLink;

        Write-ProgressHelper -Message "$($ProjectName)|Add a new Firewall rule for Port 3000(Grafana) connection" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS         
        $FWName = $ProjectName + "-FW-3000"
        $MyGCPFireWall = New-GceFirewallProtocol tcp -Port 3000 | Add-GceFirewall `
            -Name $FWName -Project $ProjectName -Network $MyGCPNetwork.SelfLink;

        Write-ProgressHelper -Message "$($ProjectName)|Get GCP Image" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS         
        $MyGCPImages = Get-GceImage -Family "ubuntu-2004-lts"
        $MyGCPImage = $MyGCPImages | Sort-Object CreationTimestamp -Descending | Select-Object *

        Write-ProgressHelper -Message "$($ProjectName)|Get GCP Machine Types" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS         
        $MyGCPImageType = Get-GceMachineType -Project $ProjectName -Zone $Zone;
        $MyGCPImageType | Select-Object Name,Description;

        Write-ProgressHelper -Message "$($ProjectName)|Create the GCP compute VM instance" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS         
        $InstName = $ProjectName + "-instance"
        $MyGCPInstance = Add-GceInstance -Project $ProjectName `
            -Zone $Zone -Name $InstName `
            -MachineType $MachineType -DiskImage $MyGCPImage -Network $MyGCPNetwork.Id;
        
        Write-ProgressHelper -Message "$($ProjectName)|Get GCP Instance details" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS         
        Get-GceInstance -Project $ProjectName `
            -Zone $Zone -Name $InstName | Select-Object *;
        
        Write-ProgressHelper -Message "$($ProjectName)|Get GCP Instance disk details" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS         
        Get-GceDisk -Project $ProjectName -Zone $Zone;

        Write-ProgressHelper -Message "$($ProjectName)|Show Connect Info" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        Write-Host "Instance-Name: $($InstName)" -ForegroundColor Cyan
        Write-Host "To Connect write: " -ForegroundColor Cyan
        Write-Host "gcloud beta compute --project <YOUR_PROJCT_NAME> ssh --zone <YOUR_GCP_ZONE> <INSTANCE-NAME>" -ForegroundColor Cyan

    } catch {

        #"Stuff Failed" | Write-Error
        #Write-Output "Ran into an issue: $($PSItem.ToString())"

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