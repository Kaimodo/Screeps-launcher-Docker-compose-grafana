<#
SCRIPT To Auto-Generate Azure-Server
#>

# Input your data here
$resGroup = "Screeps"
$location = "Westeurope"
$subNet = "ScreepsSubnet"
$vNet = "ScreepsMyVNET"
$VMSize = "Standard_B2s"
$VMName = "ScreepsVM"

# Create ResourceGroup
New-AzResourceGroup -Name $resGroup -Location $location

# Create a subnet configuration
$subnetConfig = New-AzVirtualNetworkSubnetConfig `
  -Name $subNet `
  -AddressPrefix 192.168.1.0/24

# Create a virtual network
$vnet = New-AzVirtualNetwork `
  -ResourceGroupName $resGroup `
  -Location $location `
  -Name $vNet `
  -AddressPrefix 192.168.0.0/16 `
  -Subnet $subnetConfig

# Create a public IP address and specify a DNS name
$pip = New-AzPublicIpAddress `
  -ResourceGroupName $resGroup `
  -Location $location `
  -AllocationMethod Static `
  -IdleTimeoutInMinutes 4 `
  -Name "mypublicdns$(Get-Random)"

# Create an inbound network security group rule for port ssh
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig `
  -Name "ScreepsNetworkSecurityGroupRuleSSH"  `
  -Protocol "Tcp" `
  -Direction "Inbound" `
  -Priority 1000 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 22 `
  -Access "Allow"

# Create an inbound network security group rule for port 80
$nsgRuleWeb = New-AzNetworkSecurityRuleConfig `
  -Name "ScreepsNetworkSecurityGroupRuleWWW"  `
  -Protocol "Tcp" `
  -Direction "Inbound" `
  -Priority 1001 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80 `
  -Access "Allow"

# Create an inbound network security group rule for port 21025
$nsgRuleWeb = New-AzNetworkSecurityRuleConfig `
  -Name "ScreepsNetworkSecurityGroupRule21025"  `
  -Protocol "Tcp" `
  -Direction "Inbound" `
  -Priority 1001 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 21025 `
  -Access "Allow"

# Create an inbound network security group rule for port 3000(Grafana)
$nsgRuleWeb = New-AzNetworkSecurityRuleConfig `
  -Name "ScreepsNetworkSecurityGroupRule3000"  `
  -Protocol "Tcp" `
  -Direction "Inbound" `
  -Priority 1001 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 3000 `
  -Access "Allow"

# Create a network security group
$nsg = New-AzNetworkSecurityGroup `
  -ResourceGroupName $resGroup `
  -Location $location `
  -Name "ScreepsNetworkSecurityGroup" `
  -SecurityRules $nsgRuleSSH,$nsgRuleWeb

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzNetworkInterface `
  -Name "ScreepsNic" `
  -ResourceGroupName $resGroup `
  -Location $location `
  -SubnetId $vnet.Subnets[0].Id `
  -PublicIpAddressId $pip.Id `
  -NetworkSecurityGroupId $nsg.Id

# Define a credential object
$securePassword = ConvertTo-SecureString ' ' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("azureuser", $securePassword)

# Create a virtual machine configuration
$vmConfig = New-AzVMConfig `
  -VMName $VMName `
  -VMSize $VMSize | `
Set-AzVMOperatingSystem `
  -Linux `
  -ComputerName "Screeps2VM" `
  -Credential $cred `
  -DisablePasswordAuthentication | `
Set-AzVMSourceImage `
  -PublisherName "Canonical" `
  -Offer "UbuntuServer" `
  -Skus "18.04-LTS" `
  -Version "latest" | `
Add-AzVMNetworkInterface `
  -Id $nic.Id

# Configure the SSH key
$sshPublicKey = cat ~/.ssh/id_rsa.pub
Add-AzVMSshPublicKey `
  -VM $vmconfig `
  -KeyData $sshPublicKey `
  -Path "/home/azureuser/.ssh/authorized_keys"

New-AzVM `
  -ResourceGroupName "Screeps" `
  -Location Westeurope -VM $vmConfig


