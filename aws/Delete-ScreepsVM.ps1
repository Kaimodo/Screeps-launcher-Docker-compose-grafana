
[CmdletBinding()]
param(

    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $ProfileName,

    [Parameter(Position = 1)]
    [ValidateNotNull()]
    [System.String]
    $Region,

    [Parameter(Position = 1)]
    [ValidateNotNull()]
    [System.String]
    $KeyName,

    [Parameter(Position = 1)]
    [ValidateNotNull()]
    [System.String]
    $GroupName
)

## -------
## Cleanup
## ------- 
 
$MyVPCEC2Instance =(Get-EC2Instance -ProfileName "Screeps").instances

## Terminate the ec2 instance
Remove-EC2Instance `
-InstanceId $MyVPCEC2Instance.InstanceId `
-Force `
-ProfileName $ProfileName `
-Region $Region
 
## Delete key pair
Remove-Item -Path .\myPSKeyPair.pem;
 
Remove-EC2KeyPair `
-KeyName $KeyName `
-Force `
-ProfileName $ProfileName `
-Region $Region
 
## Delete custom security group
$SecGrp = (Get-EC2SecurityGroup | Where-Object GroupName -EQ $GroupName).GroupId
foreach ($item in $SecGrp) {
    Remove-EC2SecurityGroup `
    -GroupId $item  `
    -Force    
}


## Delete the public subnet
$MySubnet = Get-EC2Subnet
foreach ($net in $MySubnet) {
    Remove-EC2Subnet `
        -SubnetId $net.SubnetId `
        -Force `
        -ProfileName $ProfileName `
        -Region $Region
    }

$MyRouteTable = Get-EC2RouteTable
foreach ($table in $MyRouteTable) {
    Remove-EC2RouteTable `
        -RouteTableId $table.RouteTableId `
        -Force `
        -ProfileName $ProfileName `
        -Region $Region
    }

 
## Delete the custom route table
$RouteAID = Get-EC2RouteTable
foreach ($Route in $RouteAID) {
    Unregister-EC2RouteTable `
        -AssociationId $Route `
        -Force `
        -ProfileName $ProfileName `
        -Region $Region
    }



## Delete internet gateway
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


 

 
