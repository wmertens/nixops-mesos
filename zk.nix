{ nrMachines ? 3 }:

with import <nixpkgs/lib>;

let

  makeMachine = n: nameValuePair "zk-${toString n}"
    ({ config, pkgs, nodes, ... }:
    let
      zkServers = concatStrings (mapAttrsToList (node: conf:
        let zk = conf.config.services.zookeeper; in
        if zk.enable then "server.${toString zk.id} = ${node}:2888:3888\n" else ""
      ) nodes);
    in {
      config.services.zookeeper = {
      	enable = true;
	id = n;
	servers = zkServers;
      };
      config.networking.firewall.enable = false;
      config.environment.systemPackages = with pkgs; [ zookeeper netcat ];
    });

in listToAttrs (map makeMachine (range 0 (nrMachines - 1)))
