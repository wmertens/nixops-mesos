{ nrMachines ? 3 }:

with import <nixpkgs/lib>;

let

  makeMachine = n: nameValuePair "zk-${toString n}"
    ({ config, pkgs, ... }: {
      config.services.zookeeper = {
      	enable = true;
	id = n;
      };
      config.environment.systemPackages = with pkgs; [ zookeeper netcat ];
    });

in listToAttrs (map makeMachine (range 0 (nrMachines - 1)))
