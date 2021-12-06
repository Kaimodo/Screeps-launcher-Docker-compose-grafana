    <#
.SYNOPSIS
    Create VM on Amazon AWS
.DESCRIPTION
	Script to Auto-Generate a VM on Amazon AWS for running screeps-launcher on it
.PARAMETER Profilename
	The UserName
.PARAMETER Region
	The Password
.PARAMETER AvailabilityZone
	The Location where the Server should be build
.PARAMETER GroupName
	The Name of the Resource-Group
.PARAMETER SubNet
	The Name of the SubNet
.PARAMETER KeyFilePath
	The Filename of the KeyFile
.PARAMETER InstanceType
	The size of the VM
.EXAMPLE
	createServerVM.ps1 -ProfileName "Screeps" -Region: "eu-west-3" -AvailabilityZone "eu-west-3b" -GroupName "Screeps" -KeyFilePath "myPSKeyPair.pem" -InstanceType "t3.micro"PS C:\> .\createServerVM.ps1 -ProfileName "Screeps" -Region: "eu-west-3" -AvailabilityZone "eu-west-3b" -GroupName "Screeps" -KeyFilePath "myPSKeyPair.pem" -InstanceType "t3.micro"
	Set's up the machine with the Values
.EXAMPLE
	PS C:\> .\createServerVM.ps1 -ProfileName "Screeps" -Region: "eu-west-3" -AvailabilityZone "eu-west-3b" -GroupName "Screeps" -Verbose
	Set's up the machine with the default Value for the InstanceType. Gives better output of what's going on.
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

    [Parameter(Position = 1, Mandatory = $true)]
    [ValidateNotNull()]
    [System.String]
    $Region=$(Throw "Region required."),

    [Parameter(Position = 2, Mandatory = $true)]
    [ValidateNotNull()]
    [System.String]
    $AvailabilityZone=$(Throw "AvailabilityZone required."),

    [Parameter(Position = 3, Mandatory = $true)]
    [ValidateNotNull()]
    [System.String]
    $GroupName=$(Throw "GroupName required."),

    [Parameter(Position = 4, Mandatory = $false)]
    [ValidateNotNull()]
    [System.String]
    $KeyFilePath="myPSKeyPair.pem",

    [Parameter(Position = 5, Mandatory = $false)]
    [ValidateNotNull()]
    [System.String]
    $InstanceType = "t3.micro"
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
        $Activity = "Creating VM and Resources"
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
        Write-ProgressHelper -Message 'Creating VPC' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        $MyVPC = (New-EC2Vpc `
            -CidrBlock "10.0.0.0/16" `
            -ProfileName $ProfileName `
            -Region $Region );

        Write-ProgressHelper -Message 'Enable DNS hostname for VPC' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        Edit-EC2VpcAttribute `
            -VpcId $MyVPC.VpcId `
            -EnableDnsHostnames $true `
            -ProfileName $ProfileName `
            -Region $Region

        Write-ProgressHelper -Message 'Creating SubNet' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        $MySubnet = (New-EC2Subnet `
            -VpcId $MyVPC.VpcId `
            -CidrBlock "10.0.1.0/24" `
            -AvailabilityZone $AvailabilityZone `
            -ProfileName $ProfileName `
            -Region $Region);

        Write-ProgressHelper -Message 'Enable Auto-assign Public IP on the Subnet' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        Edit-EC2SubnetAttribute `
            -SubnetId $MySubnet.SubnetId `
            -MapPublicIpOnLaunch $true `
            -ProfileName $ProfileName `
            -Region $Region

        Write-ProgressHelper -Message 'Creating an Internet Gateway' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        $MyInternetGateway = New-EC2InternetGateway `
            -ProfileName $ProfileName `
            -Region $Region

        Write-ProgressHelper -Message 'Attaching Internet gateway to VPC' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        Add-EC2InternetGateway `
            -VpcId $MyVPC.VpcId `
            -InternetGatewayId $MyInternetGateway.InternetGatewayId `
            -ProfileName $ProfileName `
            -Region $Region

        Write-ProgressHelper -Message 'Creating a route table' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        $MyRouteTable = (New-EC2RouteTable `
            -VpcId $MyVPC.VpcId `
            -ProfileName $ProfileName `
            -Region $Region);

        Write-ProgressHelper -Message 'Creating route to Internet Gateway' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        New-EC2Route `
            -RouteTableId $MyRouteTable.RouteTableId `
            -DestinationCidrBlock "0.0.0.0/0" `
            -GatewayId $MyInternetGateway.InternetGatewayId `
            -ProfileName $ProfileName `
            -Region $Region

        Write-ProgressHelper -Message 'Associating the public subnet with route table' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        $RouteAID = (Register-EC2RouteTable `
            -RouteTableId $MyRouteTable.RouteTableId `
            -SubnetId $MySubnet.SubnetId `
            -ProfileName $ProfileName `
            -Region $Region);

        Write-ProgressHelper -Message 'Create a security group' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        $MySecurityGroup = $(New-EC2SecurityGroup `
            -GroupName $GroupName `
            -Description "Used for SSH, Screeps and Grafana connection" `
            -VpcId $MyVPC.VpcId `
            -ProfileName $ProfileName `
            -Region $Region);

        Write-ProgressHelper -Message 'Create security group ingress rule for ssh' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        $IpRange = New-Object -TypeName Amazon.EC2.Model.IpRange
        $IpRange.CidrIp = "0.0.0.0/0"
        $IpRange.Description = "SSH from Anywhere"
        $IpPermission = New-Object Amazon.EC2.Model.IpPermission
        $IpPermission.IpProtocol = "tcp"
        $IpPermission.ToPort = 22
        $IpPermission.FromPort = 22
        $IpPermission.Ipv4Ranges = $IpRange
        Grant-EC2SecurityGroupIngress `
            -GroupId $MySecurityGroup `
            -IpPermission $IpPermission `
            -ProfileName $ProfileName `
            -Region $Region;

        Write-ProgressHelper -Message 'Create security group ingress rule for Screeps-Server' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        $IpRange = New-Object -TypeName Amazon.EC2.Model.IpRange
        $IpRange.CidrIp = "0.0.0.0/0"
        $IpRange.Description = "Screeps-Server"
        $IpPermission = New-Object Amazon.EC2.Model.IpPermission
        $IpPermission.IpProtocol = "tcp"
        $IpPermission.ToPort = 21025
        $IpPermission.FromPort = 21025
        $IpPermission.Ipv4Ranges = $IpRange
        Grant-EC2SecurityGroupIngress `
            -GroupId $MySecurityGroup `
            -IpPermission $IpPermission `
            -ProfileName $ProfileName `
            -Region $Region;

        Write-ProgressHelper -Message 'Create security group ingress rule for Screeps-Server-CLI' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        $IpRange = New-Object -TypeName Amazon.EC2.Model.IpRange
        $IpRange.CidrIp = "0.0.0.0/0"
        $IpRange.Description = "Screeps-Server CLI"
        $IpPermission = New-Object Amazon.EC2.Model.IpPermission
        $IpPermission.IpProtocol = "tcp"
        $IpPermission.ToPort = 21026
        $IpPermission.FromPort = 21026
        $IpPermission.Ipv4Ranges = $IpRange
        Grant-EC2SecurityGroupIngress `
            -GroupId $MySecurityGroup `
            -IpPermission $IpPermission `
            -ProfileName $ProfileName `
            -Region $Region;

        Write-ProgressHelper -Message 'Create security group ingress rule for Grafana' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        $IpRange = New-Object -TypeName Amazon.EC2.Model.IpRange
        $IpRange.CidrIp = "0.0.0.0/0"
        $IpRange.Description = "Screeps-Grafana"
        $IpPermission = New-Object Amazon.EC2.Model.IpPermission
        $IpPermission.IpProtocol = "tcp"
        $IpPermission.ToPort = 3000
        $IpPermission.FromPort = 3000
        $IpPermission.Ipv4Ranges = $IpRange
        Grant-EC2SecurityGroupIngress `
            -GroupId $MySecurityGroup `
            -IpPermission $IpPermission `
            -ProfileName $ProfileName `
            -Region $Region;

        Write-ProgressHelper -Message 'Get AMI ID For Your New EC2 Instance' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        $f1 = @{Name="state"; Value="available"}
        $f2 = @{Name="description"; Value="Canonical, Ubuntu, 20.04 LTS, amd64 focal image build on ????-??-??"}
        $AMI = (Get-EC2Image `
            -Filter @($f1, $f2) `
            -ProfileName $ProfileName `
            -Region $Region); 
        $Image = $AMI | Sort-Object CreationDate -Descending | Select-Object ImageId -First 1
        $Image.ImageId

        Write-ProgressHelper -Message 'Create a new key-pair' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        $FileName = Split-Path -Path $KeyFilePath -Leaf
        $myPSKeyPair = (New-EC2KeyPair `
            -KeyName $FileName `
            -ProfileName $ProfileName `
            -Region $Region); 
                
        
        $myPSKeyPair.KeyMaterial | Out-File -Encoding ascii $FileName

        Write-ProgressHelper -Message "Create new EC2 instance ($($InstanceType))" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        ## 
        $MyEC2Instance = (New-EC2Instance `
            -ImageId $Image.ImageId `
            -AssociatePublicIp $true `
            -InstanceType $InstanceType `
            -KeyName $KeyFilePath `
            -PrivateIpAddress "10.0.1.10" `
            -SecurityGroupId $MySecurityGroup `
            -SubnetId $MySubnet.SubnetId `
            -ProfileName $ProfileName `
            -Region $Region);

        Write-ProgressHelper -Message "Get EC2 Instance Details" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
        $f1 = @{Name="reservation-id"; Value=$MyEC2Instance.ReservationId}
        $MyVPCEC2Instance = (Get-EC2Instance `
            -Filter @($f1) `
            -ProfileName $ProfileName `
            -Region $Region).Instances
        $MyVPCEC2Instance


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