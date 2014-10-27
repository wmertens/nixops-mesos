{ mesosMasterCount ? 3, mesosSlaveCount ? 2 }:

with import <nixpkgs/lib>;

let
  makeNode = name: nodeFromN: n:
    nameValuePair "${name}-${toString n}" (nodeFromN n);
  makeNodes = name: nodeFromN: count:
    listToAttrs (map (makeNode name nodeFromN) (range 0 (count - 1)));

  masterNode = n: { config, pkgs, ... }:
  {
    config.services.mesos.master = {
      enable = true;
    };
    config.services.zookeeper = {
      enable = true;
      id = n;
    };
  };

  slaveNode = n: { config, pkgs, ... }:
  {
    config.services.mesos.slave.enable = true;
  };

in
  makeNodes "master" masterNode mesosMasterCount
  // (makeNodes "slave" slaveNode mesosSlaveCount)
