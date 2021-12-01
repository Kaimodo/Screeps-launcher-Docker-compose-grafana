
[CmdletBinding()]
param(

    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $ProfileName,

    [Parameter(Position = 1, Mandatory = $true)]
    [ValidateNotNull()]
    [System.String]
    $Region,

    [Parameter(Position = 2, Mandatory = $true)]
    [ValidateNotNull()]
    [System.String]
    $AvailabilityZone,

    [Parameter(Position = 3, Mandatory = $true)]
    [ValidateNotNull()]
    [System.String]
    $GroupName,

    [Parameter(Position = 4, Mandatory = $true)]
    [ValidateNotNull()]
    [System.String]
    $KeyName,

    [Parameter(Position = 5)]
    [ValidateNotNull()]
    [System.String]
    $InstanceType = "t3.micro"
)

########################################################
## How To Create An AWS EC2 Instance Using PowerShell ##
########################################################
 
## ----------------
## Create A New VPC
## ----------------
 
## Create a VPC
$MyVPC = (New-EC2Vpc `
-CidrBlock "10.0.0.0/16" `
-ProfileName $ProfileName `
-Region $Region );
 
## Enable DNS hostname for your VPC
Edit-EC2VpcAttribute `
-VpcId $MyVPC.VpcId `
-EnableDnsHostnames $true `
-ProfileName $ProfileName `
-Region $Region


## --------------------------
## Create A New Public Subnet
## --------------------------
 
## Create a Subnet
$MySubnet = (New-EC2Subnet `
-VpcId $MyVPC.VpcId `
-CidrBlock "10.0.1.0/24" `
-AvailabilityZone $AvailabilityZone `
-ProfileName $ProfileName `
-Region $Region);
 
## Enable Auto-assign Public IP on the Subnet
Edit-EC2SubnetAttribute `
-SubnetId $MySubnet.SubnetId `
-MapPublicIpOnLaunch $true `
-ProfileName $ProfileName `
-Region $Region
 
## Create an Internet Gateway
$MyInternetGateway = New-EC2InternetGateway `
-ProfileName $ProfileName `
-Region $Region
 
## Attach Internet gateway to your VPC
Add-EC2InternetGateway `
-VpcId $MyVPC.VpcId `
-InternetGatewayId $MyInternetGateway.InternetGatewayId `
-ProfileName $ProfileName `
-Region $Region
 
## Create a route table
$MyRouteTable = (New-EC2RouteTable `
-VpcId $MyVPC.VpcId `
-ProfileName $ProfileName `
-Region $Region);
 
## Create route to Internet Gateway
New-EC2Route `
-RouteTableId $MyRouteTable.RouteTableId `
-DestinationCidrBlock "0.0.0.0/0" `
-GatewayId $MyInternetGateway.InternetGatewayId `
-ProfileName $ProfileName `
-Region $Region
 
## Associate the public subnet with route table
$RouteAID = (Register-EC2RouteTable `
-RouteTableId $MyRouteTable.RouteTableId `
-SubnetId $MySubnet.SubnetId `
-ProfileName $ProfileName `
-Region $Region);


## ---------------------------
## Create A New Security Group
## ---------------------------
 
## Create a security group
$MySecurityGroup = $(New-EC2SecurityGroup `
-GroupName $GroupName `
-Description "Used for SSH and Screeps connection" `
-VpcId $MyVPC.VpcId `
-ProfileName $ProfileName `
-Region $Region);
 
## Create security group ingress rules
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

## Create security group ingress rules
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

## Create security group ingress rules
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

## Create security group ingress rules
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


## ------------------------------------
## Get AMI ID For Your New EC2 Instance
## -

## Ubuntu 20 LTS
$f1 = @{Name="state"; Value="available"}
$f2 = @{Name="description"; Value="Canonical, Ubuntu, 20.04 LTS, amd64 focal image build on ????-??-??"}
$AMI = (Get-EC2Image `
-Filter @($f1, $f2) `
-ProfileName $ProfileName `
-Region $Region); 
$Image = $AMI | Sort-Object CreationDate -Descending | Select-Object ImageId -First 1
$Image.ImageId

## ---------------------
## Create A New Key-Pair
## ---------------------
 
## Create a new key-pair
$myPSKeyPair = (New-EC2KeyPair `
-KeyName $KeyName `
-ProfileName $ProfileName `
-Region $Region); 
 
$myPSKeyPair.KeyMaterial | Out-File -Encoding ascii myPSKeyPair.pem


## -------------------------
## Create A New EC2 instance
## -------------------------
 
## Create new EC2 instance
$MyEC2Instance = (New-EC2Instance `
-ImageId $Image.ImageId `
-AssociatePublicIp $true `
-InstanceType $InstanceType `
-KeyName $KeyName `
-PrivateIpAddress "10.0.1.10" `
-SecurityGroupId $MySecurityGroup `
-SubnetId $MySubnet.SubnetId `
-ProfileName $ProfileName `
-Region $Region);
 
## Get EC2 Instance Details
$f1 = @{Name="reservation-id"; Value=$MyEC2Instance.ReservationId}
$MyVPCEC2Instance = (Get-EC2Instance `
-Filter @($f1) `
-ProfileName $ProfileName `
-Region $Region).Instances
$MyVPCEC2Instance
