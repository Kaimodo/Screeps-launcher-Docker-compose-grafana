
[CmdletBinding()]
param(

    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $ProfileName,

    [Parameter(Position = 1, Mandatory = $true)]
    [ValidateNotNull()]
    [System.String]
    $Region
)

$MyVPCEC2Instance = (Get-EC2Instance `
-ProfileName $ProfileName `
-Region $Region).Instances
## ----------------------------
## Connect To Your EC2 Instance
## ----------------------------
 
## Get EC2 Instance Status (Wait till status becomes running)
$EC2Status = (Get-EC2InstanceStatus `
-InstanceId $MyVPCEC2Instance.InstanceId `
-ProfileName $ProfileName `
-Region $Region);
$EC2Status.InstanceState.Name
 
Write-Host "Connect: ssh -i myPSKeyPair.pem ec2-user@$MyVPCEC2Instance.PublicIpAddress" -ForegroundColor green
## Try to connect to the instance
ssh -i myPSKeyPair.pem ec2-user@$MyVPCEC2Instance.PublicIpAddress
exit