# Mesos cluster configuration:
# - Find zookeeper nodes
# - Find mesos master nodes
# - Add firewall rules

with import <nixpkgs/lib>;

{
  defaults = 
    { config, pkgs, nodes, ... }:
      let
        zkServers = concatStringsSep  "," (
          mapAttrsToList (hostId: node:
            let zk = node.config.services.zookeeper; in
              if zk.enable then "${hostId}:2181" else ""
          ) nodes
        );

        allowSlave2Slave = concatStrings (
          mapAttrsToList (hostId: node:
            let mesos = node.config.services.mesos; in
              if mesos.slave.enable then ''
                iptables -A nixos-fw -s ${hostId} -p tcp -m comment --comment "Allow mesos slave ${hostId}" -j ACCEPT
              '' else ""
          ) nodes
        );

        allowSlave2Master = concatStrings (
          mapAttrsToList (hostId: node:
            let mesos = node.config.services.mesos; in
              if mesos.slave.enable then ''
                iptables -A nixos-fw -s ${hostId} -p tcp --dport 5050 -m comment --comment "Allow mesos slave ${hostId}" -j ACCEPT
              '' else ""
          ) nodes
        );

        allowMaster2Slave = concatStrings (
          mapAttrsToList (hostId: node:
            let mesos = node.config.services.mesos; in
              if mesos.master.enable then ''
                iptables -A nixos-fw -s ${hostId} -p tcp --dport 5051 -m comment --comment "Allow mesos master ${hostId}" -j ACCEPT
              '' else ""
          ) nodes
        );

        allowMaster2Master = concatStrings (
          mapAttrsToList (hostId: node:
            let mesos = node.config.services.mesos; in
              if mesos.master.enable then ''
                iptables -A nixos-fw -s ${hostId} -p tcp --dport 5050 -m comment --comment "Allow mesos master ${hostId}" -j ACCEPT
              '' else ""
          ) nodes
        );

      in
      {
        services.mesos.slave = mkIf config.services.mesos.slave.enable {
          master = "zk://${zkServers}/mesos";
        };
        networking.firewall.extraCommands = (concatStrings [
                   (optionalString config.services.mesos.slave.enable (concatStrings [ allowMaster2Slave  allowSlave2Slave ]))
                   (optionalString config.services.mesos.master.enable (concatStrings [ allowMaster2Master  allowSlave2Master ]))
                ]);
        services.mesos.master =  mkIf config.services.mesos.master.enable {
          zk = "zk://${zkServers}/mesos";
        };
      };
}
