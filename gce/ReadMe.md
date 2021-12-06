# Install via Powershell

## First set the execution policy, if not done yet

`Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

## Install the Power-Shell Module

`Install-Module GoogleCloud -Scope CurrentUser -Repository PSGallery -Force`

Type `gcloud init --console-only` to initialize Cloud SDK

## Run ps1-file

`./createServer.ps1 -ProjectName "Screeps" -Zone "europe-west3-c"` is the minimal command. u can use `-Verbose` to get extra Info of what is going on.

### GCE-Help

If u need help with the PS-Commands, here is some [help](https://public-wiki.iucc.ac.il/index.php/Using_PowerShell_to_manage_GCP_resources)

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

### From here you can [follow](../ReadMe.md)

## Remove everything

If u want to remove the VM and it's resources just call `.\deleteServer.ps1 -ProjectName "Screeps" -Zone "europe-west3-c"`

[Back to Main Readme](../ReadMe.md)
