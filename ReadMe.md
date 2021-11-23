# Screeps-launcher-Docker-compose-grafana

![ ](https://screeps.com/images/logotype-animated.svg)
![ ](/img/sampleDashboard.png)

Tested on Docker-desktop(Win) and Docker(Ubuntu20).

The example-dash and the stats.js are from
[screeps-grafana](https://github.com/screepers/screeps-grafana)

## (OPTIONAL) Setup Azure-Server [instructions](azure/readMe.md)

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

More Info here: [screeps-grafana](https://github.com/screepers/screeps-grafana)

## Usage example

I found a (working) Dashboard and a TS-Class [here](https://github.com/devnixs/screeps-stats-grafana)
YOu can find it in the `grafana_sample` Folder.

### Setup Step in Screeps

To call it just

```js
import { StatsManager } from "stats-manager.ts";
```

in your main.ts(js) and run

```js
StatsManager.runForAllRooms();
```

at the end of your Loop.

### Setup Step in Grafana

Import `newDash.json` as a new DashBoard and all should be working.

## Adding Grafana Plugins

Just run `docker-compose exec grafana grafana-cli plugins install grafana-clock-panel` to install the plugins, then `docker-compose restart grafana` to apply. Refresh your browser and voila!

Additional Plugins can be found [here](https://grafana.com/grafana/plugins/).
