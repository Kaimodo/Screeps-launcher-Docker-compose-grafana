    <#
.SYNOPSIS
    Create VM on AWS
.DESCRIPTION
	Script to Auto-Generate a VM on Amazon AWS for running screeps-launcher on it
.PARAMETER Location
	The Location where the Server should be build
.PARAMETER ResGroup
	The Name of the Resource-Group
.PARAMETER SubNet
	The Name of the SubNet
.PARAMETER $VNet
	The Name of the Virtual-Net
.PARAMETER VMSize
	The size of the VM
.PARAMETER VMName
	The Name of the Virtual-machine
.EXAMPLE
	PS C:\> .\setupServer.ps1 
	Set's up the machine with the default Values
.EXAMPLE
	PS C:\> .\setupServer.ps1 -Location "westeurope" -ResGroup "Screeps"
	Set's up the machine with the default Values expect Location and ResGroup
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
    $Location = "Westeurope",
    
    [Parameter(	Position = 1,
        Mandatory = $false,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [System.String]
    $ResGroup = "Screeps",
    
    [Parameter(	Position = 2,
        Mandatory = $false,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [System.String]
    $SubNet = "ScreepsSubnet",
    
    [Parameter(	Position = 3,
        Mandatory = $false,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [System.String]
    $VNet = "ScreepsMyVNET",
    
    [Parameter(	Position = 4,
        Mandatory = $false,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [System.String]
    $VMSize = "Standard_B2s",  #  Standard_D1_v2,
    
    [Parameter(	Position = 5,
        Mandatory = $false,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [System.String]
    $VMName = "ScreepsVM"
)

begin {
  $FunctionName = $MyInvocation.MyCommand.Name
  Write-Verbose "$($FunctionName): Begin"
  $TempErrAct = $ErrorActionPreference
  $ErrorActionPreference = "Stop"
  try {
        Get-Content .\bal.psx
    }
    catch {

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

