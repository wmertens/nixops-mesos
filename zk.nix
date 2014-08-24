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

      allowOthers = concatStrings (mapAttrsToList (node: conf:
        let zk = conf.config.services.zookeeper; in
        if zk.enable then ''
          iptables -A nixos-fw -s ${node} -p tcp -m multiport --dports 2888,3888 -m comment --comment "Allow zookeeper node ${node}" -j ACCEPT
        '' else ""
      ) nodes);

    in {
      config.services.zookeeper = {
      	enable = true;
	id = n;
	servers = zkServers;
      };
      config.networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 2181 ];
        extraCommands = allowOthers;
      };
      config.environment.systemPackages = with pkgs; [ zookeeper netcat ];
    });

in listToAttrs (map makeMachine (range 0 (nrMachines - 1)))
