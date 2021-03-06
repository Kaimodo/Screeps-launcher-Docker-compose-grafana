<#
.SYNOPSIS
    Delete VM and CleanUp on Microsoft Azure
.DESCRIPTION
	Script to delete & cleanup a VM on Microsoft Azure
.PARAMETER VMName
	The Name of the Virtual-machine
.EXAMPLE
	PS C:\> .\deleteServer.ps1 -VMName "NAME_OF_YOUR_VM"
	Deletes the machine with the given Name
.EXAMPLE
	PS C:\> .\deleteServer.ps1 -VMName "NAME_OF_YOUR_VM" -Verbose
	Deletes the machine with the given Name but gives better output of what's going on.
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
    $VMName = $(Throw "VM-Name required.")
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
            Write-Verbose "$($FunctionName): Try"  
            $TS = ([System.Management.Automation.PsParser]::Tokenize((Get-Content $MyInvocation.MyCommand), [ref]$null) | Where-Object { $_.Type -eq 'Command' -and $_.Content -eq 'Write-ProgressHelper' }).Count
            Write-Host -NoNewline -ForegroundColor Green "VM-name you would like to remove: $($VMName)"
            $vm = Get-AzVm -Name $VMName
            Write-ProgressHelper -Message 'Searching VM' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
            if ($vm) {
                Write-Verbose "$($FunctionName): VM $($VMName) exists"
                Write-ProgressHelper -Message 'Found VM' -StepNumber ($stepCounter++) -TotalS $TS
                $RGName=$vm.ResourceGroupName
                Write-ProgressHelper -Message 'Searching Resource Group' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
                Write-Host -ForegroundColor Cyan 'Resource Group Name is identified as-' $RGName
                $diagSa = [regex]::match($vm.DiagnosticsProfile.bootDiagnostics.storageUri, '^http[s]?://(.+?)\.').groups[1].value
                Write-Host -ForegroundColor Cyan 'Marking Disks for deletion...'
                $tags = @{"VMName"=$VMName; "Delete Ready"="Yes"}
                $osDiskName = $vm.StorageProfile.OSDisk.Name
                $datadisks = $vm.StorageProfile.DataDisks
                $ResourceID = (Get-Azdisk -Name $osDiskName).id
                Write-ProgressHelper -Message 'Searching Disks for deletion' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
                New-AzTag -ResourceId $ResourceID -Tag $tags | Out-Null
                if ($vm.StorageProfile.DataDisks.Count -gt 0) {
                    foreach ($datadisks in $vm.StorageProfile.DataDisks){
                        $datadiskname=$datadisks.name
                        $ResourceID = (Get-Azdisk -Name $datadiskname).id
                        New-AzTag -ResourceId $ResourceID -Tag $tags | Out-Null
                    }
                }
                if ($vm.Name.Length -gt 9){
                    $i = 9
                }
                else {
                    $i = $vm.Name.Length - 1
                }
                $azResourceParams = @{
                    'ResourceName' = $VMName
                    'ResourceType' = 'Microsoft.Compute/virtualMachines'
                    'ResourceGroupName' = $RGName
                }
                $vmResource = Get-AzResource @azResourceParams
                $vmId = $vmResource.Properties.VmId
                $diagContainerName = ('bootdiagnostics-{0}-{1}' -f $vm.Name.ToLower().Substring(0, $i), $vmId)
                $diagSaRg = (Get-AzStorageAccount | where { $_.StorageAccountName -eq $diagSa }).ResourceGroupName
                $saParams = @{
                    'ResourceGroupName' = $diagSaRg
                    'Name' = $diagSa
                }
                Write-Host -ForegroundColor Cyan 'Removing Boot Diagnostic disk..'
                if ($diagSa){
                    Get-AzStorageAccount @saParams | Get-AzStorageContainer | where {$_.Name-eq $diagContainerName} | Remove-AzStorageContainer -Force
                }
                else {
                    Write-Host -ForegroundColor Green "No Boot Diagnostics Disk found attached to the VM!"
                }
                Write-ProgressHelper -Message 'Removing VM' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
                Write-Host -ForegroundColor Cyan 'Removing Virtual Machine-' $VMName 'in Resource Group-'$RGName '...'
                $null = $vm | Remove-AzVM -Force
                Write-Host -ForegroundColor Cyan 'Removing Network Interface Cards, Public IP Address(s) used by the VM...'
                Write-ProgressHelper -Message 'Removing Network stuff' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
                foreach($nicUri in $vm.NetworkProfile.NetworkInterfaces.Id) {
                    $nic = Get-AzNetworkInterface -ResourceGroupName $vm.ResourceGroupName -Name $nicUri.Split('/')[-1]
                    Remove-AzNetworkInterface -Name $nic.Name -ResourceGroupName $vm.ResourceGroupName -Force
                    foreach($ipConfig in $nic.IpConfigurations) {
                        if($ipConfig.PublicIpAddress -ne $null){
                            Remove-AzPublicIpAddress -ResourceGroupName $vm.ResourceGroupName -Name $ipConfig.PublicIpAddress.Id.Split('/')[-1] -Force
                        }
                    }
                }
                Write-Host -ForegroundColor Cyan 'Removing OS disk and Data Disk(s) used by the VM..'
                Get-AzResource -tag $tags | where{$_.resourcegroupname -eq $RGName}| Remove-AzResource -force | Out-Null
                Write-ProgressHelper -Message 'Completed removing VM' -Sleep 2 -StepNumber ($stepCounter++) -TotalS $TS
                Write-Host -ForegroundColor Green 'Azure Virtual Machine-' $VMName 'and all the resources associated with the VM were removed sucesfully...'
            }
            else {
                Write-Host -ForegroundColor Red "The VM name($($VMName)) entered doesn't exist in your connected Azure Tenant! Kindly check the name entered and restart the script with correct VM name..."
            }
        }
        catch {
        
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