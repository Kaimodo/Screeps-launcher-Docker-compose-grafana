[CmdletBinding()]
param(
   
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $Region
)


$accountId = @(get-ec2securitygroup -GroupNames "default")[0].OwnerId
$ec2 = (Get-Ec2Instance -InstanceId 99999999999999999 -Region $Region).Instances
if ($ec2.PublicIpAddress) {
    if ($ec2.NetworkInterfaces.Association.IpOwnerId -like $AccountId) {
        Write-Output ("Elastic IP: {0}" -f $ec2.PublicIpAddress)
    }
    else {
        Write-Output ("AWS Public IP Pool {0}" -f $ec2.PublicIpAddress)
    }
}