# Install via Powershell

## First set the execution policy, if not done yet

`Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

## Install the Power-Shell Module

`Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force`

## Sign in

`Connect-AzAccount`

## Create SSH-Key

`ssh-keygen -m PEM -t rsa -b 4096`

## Edit the setupServer.ps1

- $resGroup = "Screeps"
- $location = "Westeurope"
- $subNet = "ScreepsSubnet"
- $vNet = "ScreepsMyVNET"
- $VMName = "ScreepsMV"
- $VMSize = "Standard_B2s"

are the standards from the file itself.

## Run ps1-file

`./setupServer.ps1`

## ToDo's after the script ran

Get the public IP of your Server via `Get-AzPublicIpAddress -ResourceGroupName "Screeps" | Select "IpAddress"`

Connect to it using `ssh azureuser@IP-AddressFromAbove`

## Install Docker

- `sudo apt install apt-transport-https ca-certificates curl software-properties-common`
- `curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -`
- `sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"`
- `sudo apt install docker-ce`
- `sudo usermod -aG docker ${USER}`
- `sudo usermod -aG docker USERNAME`

## Install Docker-Compose

- `sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose`
- `sudo chmod +x /usr/local/bin/docker-compose`
- `cd /opt`
- `sudo git clone https://github.com/Kaimodo/Screeps-launcher-Docker-compose-grafana`
- `cd Screeps-launcher-Docker-compose-grafana`

### From here [follow](../ReadMe.md)
