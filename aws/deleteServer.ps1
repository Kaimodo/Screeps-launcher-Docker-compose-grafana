
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
	PS C:\> .\deleteServer.ps1 -ProfileName "Screeps" -Region: "eu-west-3" -KeyFilePath "myPSKeyPair.pem" -GroupName "Screeps"
	Delete the machine with the Values
.EXAMPLE
	PS C:\> .\deleteServer.ps1 -ProfileName "Screeps" -Region: "eu-west-3" -GroupName "Screeps" -Verbose
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
        Write-Verbose "$($FunctionName): Process.try"
        $TS = ([System.Management.Automation.PsParser]::Tokenize((Get-Content $MyInvocation.MyCommand), [ref]$null) | Where-Object { $_.Type -eq 'Command' -and $_.Content -eq 'Write-ProgressHelper' }).Count

        Write-ProgressHelper -Message "Getting EC2-Instance" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        $MyVPCEC2Instance =(Get-EC2Instance -ProfileName $ProfileName).instances

        Write-ProgressHelper -Message "Terminating EC2-Instance" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        try {
            Remove-EC2Instance `
                -InstanceId $MyVPCEC2Instance.InstanceId `
                -Force `
                -ProfileName $ProfileName `
                -Region $Region
        } catch {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            Write-Output "`n $ErrorMessage "
            Write-Output "`n $FailedItem "
        }
        

        Write-ProgressHelper -Message "Delete key pair" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        if (Test-Path -Path $KeyFilePath) {
            try {
                $fileName = Split-Path -Path $KeyFilePath -Leaf
                Remove-EC2KeyPair `
                    -KeyName $fileName `
                    -Force `
                    -ProfileName $ProfileName `
                    -Region $Region
                Remove-Item -Path $KeyFilePath;

            } catch {
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                Write-Output "`n $ErrorMessage "
                Write-Output "`n $FailedItem "
            } 
        } else {
            try {
                $file = Split-Path -Path $KeyFilePath -Leaf
                $folder = Split-Path -Path $KeyFilePath
                Write-Host "$($FunctionName): File [$($file)] does not Exist in Folder [$($folder)]" -ForegroundColor Red
                $fileName = Split-Path -Path $KeyFilePath -Leaf
                Remove-EC2KeyPair `
                    -KeyName $fileName `
                    -Force `
                    -ProfileName $ProfileName `
                    -Region $Region
            } catch {
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                Write-Output "`n $ErrorMessage "
                Write-Output "`n $FailedItem "
            }
        }
     
        Write-ProgressHelper -Message "Get VPC" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        $MyVPCs = Get-EC2Vpc -ProfileName $ProfileName
        foreach($VPC in $MyVPCs) {
            $VPCId = $null
            $VPCId = $VPC.VpcId

            Write-ProgressHelper -Message "Dismounting Internet gateway" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
            $MyInternetGateway = Get-EC2InternetGateway -ProfileName $ProfileName -Region $Region
            foreach ($GateWay in $MyInternetGateway) {
                Dismount-EC2InternetGateway `
                -VpcId $VPCId `
                -InternetGatewayId $GateWay.InternetGatewayId `
                -Force `
                -ProfileName $ProfileName `
                -Region $Region
            
            Write-ProgressHelper -Message "Removing Internet gateway" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
            Remove-EC2InternetGateway `
                -InternetGatewayId $GateWay.InternetGatewayId `
                -Force `
                -ProfileName $ProfileName `
                -Region $Region
            }

            Write-ProgressHelper -Message "Delete the public subnet" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
            $MySubnet = Get-EC2Subnet
            foreach ($net in $MySubnet) {
                Remove-EC2Subnet `
                    -SubnetId $net.SubnetId `
                    -Force `
                    -ProfileName $ProfileName `
                    -Region $Region
            }

            Write-ProgressHelper -Message "Delete route AID" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
            $MyRouteTable = Get-EC2RouteTable
            foreach ($table in $MyRouteTable) {
                $RouteTableId = $null
                $RouteTableAssociations = $null
                $RouteTableId = $table.RouteTableId
                $RouteTableAssociations = $table.Associations                
                foreach ($RTBAssoc in $RouteTableAssociations) {
                    if (!$RTBAssoc.Main) {
                        try {
                            Write-ProgressHelper -Message "Unregister RoteTable" -Sleep 1 -StepNumber ($stepCounter++) -TotalS $TS
                            $RTBUnregister = Unregister-EC2RouteTable -AssociationId $RTBAssocId -Region $Region -Force
                        } catch {
                            ErrorMessage = $_.Exception.Message
                            $FailedItem = $_.Exception.ItemName
                            Write-Output "`n $ErrorMessage "
                            Write-Output "`n $FailedItem "
                        }
                        try {
                            Write-ProgressHelper -Message "Delete RoteTable" -Sleep 1 -StepNumber ($stepCounter++) -TotalS $TS
                            $RTBDelete = Remove-EC2RouteTable -RouteTableId $RouteTableId -Region $Region -Force
                        } catch {
                            ErrorMessage = $_.Exception.Message
                            $FailedItem = $_.Exception.ItemName
                            Write-Output "`n $ErrorMessage "
                            Write-Output "`n $FailedItem "
                        }                        
                    }
                }
                try {
                    $SecurityGroups = $null
                    $SecurityGroups = (Get-EC2SecurityGroup | Where-Object GroupName -EQ $GroupName).GroupId
                    
                    foreach($SecurityGroup in $SecurityGroups) {
                        Write-ProgressHelper -Message "Removing Security Group $($SecurityGroup.GroupName)" -Sleep 1 -StepNumber ($stepCounter++) -TotalS $TS
                        $SecurityGroupName = $null
                        $SecurityGroupName = $SecurityGroup.GroupName
                        $SecurityGroupId = $null
                        $SecurityGroupId = $SecurityGroup.GroupId
                        Remove-EC2SecurityGroup `
                            -GroupId $SecurityGroupId  `
                            -GroupName $SecurityGroupName `
                            -Force
                    }
                } catch {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    Write-Output "`n $ErrorMessage "
                    Write-Output "`n $FailedItem "
                }
                try {
                    Write-ProgressHelper -Message "Removing Ec2Vpc" -Sleep 1 -StepNumber ($stepCounter++) -TotalS $TS
                    Remove-EC2Vpc -VpcId $VPCId -Region $Region -Force
                } catch {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    Write-Output "`n $ErrorMessage "
                    Write-Output "`n $FailedItem "
                }
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