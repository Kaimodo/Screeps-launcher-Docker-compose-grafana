    <#
.SYNOPSIS
    Create VM on Azure
.DESCRIPTION
	Script to Auto-Generate a VM on Microsoft Azure for running screeps-launcher on it
.PARAMETER User
	The UserName
.PARAMETER Password
	The Password
.PARAMETER Location
	The Location where the Server should be build
.PARAMETER ResGroup
	The Name of the Resource-Group
.PARAMETER SubNet
	The Name of the SubNet
.PARAMETER VNet
	The Name of the Virtual-Net
.PARAMETER VMSize
	The size of the VM
.PARAMETER VMName
	The Name of the Virtual-machine
.EXAMPLE
	PS C:\> .\createServer.ps1 -User "USERNAME" -Password "YOURPASS"
	Set's up the machine with the default Values
.EXAMPLE
	PS C:\> .\createServer.ps1 -User "USERNAME" -Password "YOURPASS" -Verbose
	Set's up the machine with the default Values but gives better output of what's going on.
.EXAMPLE
	PS C:\> .\createServer.ps1 -User "USERNAME" -Password "YOURPASS" -Location "westeurope" -ResGroup "Screeps"
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
      Mandatory = $true,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true
    )]
    [System.String]
    $User=$(Throw "User required."),

    [Parameter(	Position = 1,
      Mandatory = $true,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true
    )]
    [Security.SecureString]
    $Password=$(Throw "Password required."),

    [Parameter(	Position = 2,
        Mandatory = $false,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [System.String]
    $Location = "Westeurope",
    
    [Parameter(	Position = 3,
        Mandatory = $false,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [System.String]
    $ResGroup = "Screeps",
    
    [Parameter(	Position = 4,
        Mandatory = $false,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [System.String]
    $SubNet = "ScreepsSubnet",
    
    [Parameter(	Position = 5,
        Mandatory = $false,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [System.String]
    $VNet = "ScreepsMyVNET",
    
    [Parameter(	Position = 6,
        Mandatory = $false,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [System.String]
    $VMSize = "Standard_B2s",  #  Standard_D1_v2,
    
    [Parameter(	Position = 7,
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
    
    Write-Verbose "$($FunctionName): Create ResourceGroup: $($ResGroup) in Location: $($Location)"
    Write-ProgressHelper -Message "Create ResourceGroup: $($ResGroup) in Location: $($Location)" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS 
    New-AzResourceGroup -Name $ResGroup -Location $Location

    Write-Verbose "$($FunctionName): Create a subnet configuration with Name: $($SubNet)"
    Write-ProgressHelper -Message "Create a subnet configuration with Name: $($SubNet)" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
    $SubNetConfig = New-AzVirtualNetworkSubnetConfig `
      -Name $SubNet `
      -AddressPrefix 192.168.1.0/24

    Write-Verbose "$($FunctionName): Create a virtual network"
    Write-ProgressHelper -Message "Create a virtual network" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS 
    $VNet = New-AzVirtualNetwork `
      -ResourceGroupName $ResGroup `
      -Location $Location `
      -Name $VNet `
      -AddressPrefix 192.168.0.0/16 `
      -Subnet $SubNetConfig

    Write-Verbose "$($FunctionName): Create a public IP address and specify a DNS name"
    Write-ProgressHelper -Message "Create a public IP address and specify a DNS name" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS 
    $pip = New-AzPublicIpAddress `
      -ResourceGroupName $ResGroup `
      -Location $Location `
      -AllocationMethod Static `
      -IdleTimeoutInMinutes 4 `
      -Name "mypublicdns$(Get-Random)"

    Write-Verbose "$($FunctionName): Create an inbound network security group rule for port ssh"
    Write-ProgressHelper -Message "Create an inbound network security group rule for port ssh" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
    $count = 1
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
    
    Write-Verbose "$($FunctionName): Create an inbound network security group rule for port 80"
    Write-ProgressHelper -Message "Create an inbound network security group rule for port 80" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS 
    $count++
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
      
    Write-Verbose "$($FunctionName): Create an inbound network security group rule for port 21025"
    Write-ProgressHelper -Message "Create an inbound network security group rule for port 21025" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
    count++
    $nsgRuleScreeps = New-AzNetworkSecurityRuleConfig `
      -Name "ScreepsNetworkSecurityGroupRule21025-Screeps"  `
      -Protocol "Tcp" `
      -Direction "Inbound" `
      -Priority 1001 `
      -SourceAddressPrefix * `
      -SourcePortRange * `
      -DestinationAddressPrefix * `
      -DestinationPortRange 21025 `
      -Access "Allow"

    Write-Verbose "$($FunctionName): Create an inbound network security group rule for port 3000 (Grafana)"
    Write-ProgressHelper -Message "Create an inbound network security group rule for port 3000 (Grafana)" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
    count++
    $nsgRuleGrafana = New-AzNetworkSecurityRuleConfig `
      -Name "ScreepsNetworkSecurityGroupRule3000-Grafana"  `
      -Protocol "Tcp" `
      -Direction "Inbound" `
      -Priority 1001 `
      -SourceAddressPrefix * `
      -SourcePortRange * `
      -DestinationAddressPrefix * `
      -DestinationPortRange 3000 `
      -Access "Allow"

    Write-Verbose "$($FunctionName): Create a network security group with $(count) Rules"
    Write-ProgressHelper -Message "Create a network security group with $(count) Rules" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
    $nsg = New-AzNetworkSecurityGroup `
      -ResourceGroupName $ResGroup `
      -Location $Location `
      -Name "ScreepsNetworkSecurityGroup" `
      -SecurityRules $nsgRuleSSH,$nsgRuleWeb,$nsgRuleScreeps,$nsgRuleGrafana

    Write-Verbose "$($FunctionName): Create a virtual network card and associate with public IP address and NSG"
    Write-ProgressHelper -Message "Create a virtual network card and associate with public IP address and NSG" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
    $nic = New-AzNetworkInterface `
      -Name "ScreepsNic" `
      -ResourceGroupName $ResGroup `
      -Location $Location `
      -SubnetId $VNet.Subnets[0].Id `
      -PublicIpAddressId $pip.Id `
      -NetworkSecurityGroupId $nsg.Id

    Write-Verbose "$($FunctionName): Define a credential object for user: $($User)"
    Write-ProgressHelper -Message "Define a credential object for user: $($User)" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
    #$securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ($User, $Password)

    Write-Verbose "$($FunctionName): Create a virtual machine configuration for VM: $($VMName) with size: $($VMSize)"
    Write-ProgressHelper -Message "Create a virtual machine configuration for VM: $($VMName) with size: $($VMSize)" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
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
      -Skus "20.04-LTS" `
      -Version "latest" | `
    Add-AzVMNetworkInterface `
      -Id $nic.Id

    Write-Verbose "$($FunctionName): Configure the SSH key"
    Write-ProgressHelper -Message "Configure the SSH key" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
    $sshPublicKey = Get-Content ~/.ssh/id_rsa.pub
    Add-AzVMSshPublicKey `
      -VM $vmconfig `
      -KeyData $sshPublicKey `
      -Path "/home/azureuser/.ssh/authorized_keys"

    Write-Verbose "$($FunctionName): Creating mmachine in ResourceGroup: $($ResGroup) in Location: $($Location)"
    Write-ProgressHelper -Message "Creating mmachine in ResourceGroup: $($ResGroup) in Location: $($Location)" -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
    New-AzVM `
      -ResourceGroupName $ResGroup `
      -Location $Location -VM $vmConfig
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

end {
  Write-Verbose "$($FunctionName): End."
  $ErrorActionPreference = $TempErrAct
}







