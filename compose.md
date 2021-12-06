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

([Back to ReadMe](./ReadMe.md))
