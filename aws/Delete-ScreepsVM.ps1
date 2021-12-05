
    <#
.SYNOPSIS
    Delete VM on Amazon AWS
.DESCRIPTION
	Script to Auto-Delete a VM on Amazon AWS for running screeps-launcher on it
.PARAMETER Profilename
	The UserName
.PARAMETER Region
	The Password
.PARAMETER KeyFilePath
	The Name of the Virtual-Net
.PARAMETER GroupName
	The Name of the Resource-Group
.EXAMPLE
	PS C:\> .\Delete-ScreepsVM.ps1 -ProfileName "Screeps" -Region: "eu-west-3" -KeyFilePath "myPSKeyPair.pem" -GroupName "Screeps"
	Delete the machine with the Values
.EXAMPLE
	PS C:\> .\Delete-ScreepsVM.ps1 -ProfileName "Screeps" -Region: "eu-west-3" -GroupName "Screeps" -Verbose
	Delete the machine with the Values. Gives better output of what's going on.
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

    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $ProfileName=$(Throw "ProfileName required."),

    [Parameter(Position = 1)]
    [ValidateNotNull()]
    [System.String]
    $Region=$(Throw "Region required."),

    [Parameter(Position = 2)]
    [ValidateNotNull()]
    [System.String]
    $KeyFilePath="myPSKeyPair.pem",

    [Parameter(Position = 3)]
    [ValidateNotNull()]
    [System.String]
    $GroupName=$(Throw "GroupName required.")
)

begin {
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin"
    $TempErrAct = $ErrorActionPreference
    $ErrorActionPreference = "Stop"
    function Write-ProgressHelper {
        param (
            [int]$StepNumber,
            [ValidateRange("Positive")]
            [int]$Sleep,
            [string]$Message
        )
  
    Write-Progress -Activity 'Deleting VM and Resources' -Status $Message -PercentComplete (($StepNumber / $steps) * 100)
    $script:steps = ([System.Management.Automation.PsParser]::Tokenize((Get-Content "$PSScriptRoot\$($MyInvocation.MyCommand.Name)"), [ref]$null) | Where-Object { $_.Type -eq 'Command' -and $_.Content -eq 'Write-ProgressHelper' }).Count
    $stepCounter = 0
    }
}

process {
    Write-Verbose "$($FunctionName): Process"
    try {
        Write-Verbose "$($FunctionName): Process.try"
        Write-ProgressHelper -Message "Getting EC2-Instance" -Sleep 2 -StepNumber ($stepCounter++)
        $MyVPCEC2Instance =(Get-EC2Instance -ProfileName "Screeps").instances

        Write-ProgressHelper -Message "Terminating EC2-Instance" -Sleep 2 -StepNumber ($stepCounter++)
        Remove-EC2Instance `
            -InstanceId $MyVPCEC2Instance.InstanceId `
            -Force `
            -ProfileName $ProfileName `
            -Region $Region

        Write-ProgressHelper -Message "Delete key pair" -Sleep 2 -StepNumber ($stepCounter++)
        if (Test-Path -Path $KeyFilePath) {
            try {
                Remove-Item -Path $KeyFilePath;
            } catch {
                throw $_.Exception.Message
            } 
        } else {
            try {
                $file = Split-Path -Path $KeyFilePath -Leaf
                $folder = Split-Path -Path $KeyFilePath
                Write-Host "$($FunctionName): File [$($file)] does not Exist in Folder [$($folder)]" -ForegroundColor Red
                continue
            } catch {
                throw $_.Exception.Message
            }
        }
        $fileName = Split-Path -Path $KeyFilePath -Leaf
        Remove-EC2KeyPair `
            -KeyName $fileName `
            -Force `
            -ProfileName $ProfileName `
            -Region $Region

        Write-ProgressHelper -Message "Delete custom security group" -Sleep 2 -StepNumber ($stepCounter++)
        $SecGrp = (Get-EC2SecurityGroup | Where-Object GroupName -EQ $GroupName).GroupId
        foreach ($item in $SecGrp) {
            Remove-EC2SecurityGroup `
            -GroupId $item  `
            -Force    
        }

        Write-ProgressHelper -Message "Delete the public subnet" -Sleep 2 -StepNumber ($stepCounter++)
        $MySubnet = Get-EC2Subnet
        foreach ($net in $MySubnet) {
            Remove-EC2Subnet `
                -SubnetId $net.SubnetId `
                -Force `
                -ProfileName $ProfileName `
                -Region $Region
        }

        Write-ProgressHelper -Message "Delete the route table" -Sleep 2 -StepNumber ($stepCounter++)        
        $MyRouteTable = Get-EC2RouteTable
        foreach ($table in $MyRouteTable) {
            Remove-EC2RouteTable `
                -RouteTableId $table.RouteTableId `
                -Force `
                -ProfileName $ProfileName `
                -Region $Region
        }

        Write-ProgressHelper -Message "Delete route AID" -Sleep 2 -StepNumber ($stepCounter++)
        $RouteAID = Get-EC2RouteTable
        foreach ($Route in $RouteAID) {
            Unregister-EC2RouteTable `
                -AssociationId $Route `
                -Force `
                -ProfileName $ProfileName `
                -Region $Region
        }   

        Write-ProgressHelper -Message "Delete internet gateway" -Sleep 2 -StepNumber ($stepCounter++)
        $MyVPC = Get-EC2Vpc -ProfileName $ProfileName

        foreach ($item in $MyVPC) {
            $MyInternetGateway = Get-EC2InternetGateway -ProfileName $ProfileName -Region $Region
            foreach ($GateWay in $MyInternetGateway) {
                Dismount-EC2InternetGateway `
                -VpcId $item.VpcId `
                -InternetGatewayId $GateWay.InternetGatewayId `
                -Force `
                -ProfileName $ProfileName `
                -Region $Region
            
            Remove-EC2InternetGateway `
                -InternetGatewayId $GateWay.InternetGatewayId `
                -Force `
                -ProfileName $ProfileName `
                -Region $Region

            ## Delete the vpc
            Remove-EC2Vpc `
                -VpcId $item.VpcId `
                -Force `
                -ProfileName $ProfileName `
                -Region $Region
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