{ mesosMasterCount ? 3, mesosSlaveCount ? 2 }:

with import <nixpkgs/lib>;

let

  makeMaster = n: nameValuePair "master-${toString n}"
    ({ config, pkgs, ... }: {
      config.services.mesos.master = {
        enable = true;
        quorum=0;  # TODO calc this
      };
      config.services.zookeeper = {
        enable = true;
        id = n;
      };
    });

  makeSlave = n: nameValuePair "slave-${toString n}"
    ({ config, pkgs, ... }: {
      config.services.mesos.slave.enable = true;
    });

in listToAttrs (
  (map makeMaster (range 0 (mesosMasterCount - 1)))
  ++ (map makeSlave (range 0 (mesosSlaveCount - 1)))
)