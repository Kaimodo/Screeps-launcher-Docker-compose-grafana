# WIP Screeps-launcher-Docker-compose-grafana

![ ](https://screeps.com/images/logotype-animated.svg)

This is not completely running as of 22.11.2021
U can rename `docker.compose.yml.nografana` to `docker.compose.yml` this setup runs smooth. I am still working on the grafana part.

## Installation steps

- Copy the `config.yml.sample` and change it to `config.yml`
- Edit `config.yml` and paste in your Steam-api-key. Feel free to change other thinks. If u need help for the config-file go to: [https://github.com/screepers/screeps-launcher]
- Copy the `/cfg/stats_setup.json.sample` and change it to `/cfg/stats_setup.json`
- Change Username and Password
- run `docker-compose up -d` and Wait until it is done starting the docker images and settle on mongo status messages.
- Open another terminal in that folder. Run `docker-compose exec screeps screeps-launcher cli`. This is a command-line interface to control your new private server.
- In the CLI, run `system.resetAllData()` to initialize the database. Unless you want to poke around, use `Ctrl-d` or `Ctrl-x` to exit the cli.
- Run `docker-compose restart screeps` to reboot the private server.

## Accessing the Server

- Connect via Steam-client and use Private server tab
- Host: _localhost_
- Port: _21025_
- Server password: _<leave blank, unless configured otherwise>_

### (optional) Change Server password

- Connect to Cli as described in Installation Steps.
- Type in `setPassword("USER","PASS")`

## Grafana

Access Grafana at [http://localhost:3000/]. You'll find your stats in the default data source, under screeps.privateserver.
