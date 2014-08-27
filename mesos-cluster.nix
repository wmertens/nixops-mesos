# Mesos cluster configuration:
# - Find zookeeper nodes
# - Find mesos master nodes
# - Add firewall rules

with import <nixpkgs/lib>;

{
  defaults = 
    { config, pkgs, nodes, ... }:
    let
        isMaster = config.services.mesos.master.enable;
        isSlave = config.services.mesos.slave.enable;
        mapNodesToList = f: mapAttrsToList f nodes;
    in mkIf (isMaster || isSlave) (
      let
        zkServers = concatStringsSep  "," (remove "" 
          (mapNodesToList (hostId: node:
              let zk = node.config.services.zookeeper; in
                if zk.enable then "${hostId}:2181" else ""
            ))
        );

        allowSlave2Slave = concatStrings (
          mapNodesToList (hostId: node:
            let mesos = node.config.services.mesos; in
              if mesos.slave.enable then ''
                iptables -A nixos-fw -s ${hostId} -p tcp -m comment --comment "Allow mesos slave ${hostId}" -j ACCEPT
              '' else ""
          )
        );

        allowSlave2Master = concatStrings (
          mapNodesToList (hostId: node:
            let mesos = node.config.services.mesos; in
              if mesos.slave.enable then ''
                iptables -A nixos-fw -s ${hostId} -p tcp --dport 5050 -m comment --comment "Allow mesos slave ${hostId}" -j ACCEPT
              '' else ""
          )
        );

        allowMaster2Slave = concatStrings (
          mapNodesToList (hostId: node:
            let mesos = node.config.services.mesos; in
              if mesos.master.enable then ''
                iptables -A nixos-fw -s ${hostId} -p tcp --dport 5051 -m comment --comment "Allow mesos master ${hostId}" -j ACCEPT
              '' else ""
          )
        );

        allowMaster2Master = concatStrings (
          mapNodesToList (hostId: node:
            let mesos = node.config.services.mesos; in
              if mesos.master.enable then ''
                iptables -A nixos-fw -s ${hostId} -p tcp --dport 5050 -m comment --comment "Allow mesos master ${hostId}" -j ACCEPT
              '' else ""
          )
        );

        masterCount = count (x: x.config.services.mesos.master.enable)
          (attrValues nodes);
      in let
        quorum = if masterCount > 1 then ((builtins.div masterCount 2) + 1) else 0;
      in
      {
        services.mesos.master =  mkIf isMaster {
          zk = "zk://${zkServers}/mesos";
          inherit quorum;
        };

        services.mesos.slave = mkIf isSlave {
          master = "zk://${zkServers}/mesos";
        };

        networking.firewall.extraCommands = (concatStrings [
         (optionalString isSlave (concatStrings [ allowMaster2Slave  allowSlave2Slave ]))
         (optionalString isMaster (concatStrings [ allowMaster2Master  allowSlave2Master ]))
        ]);

        environment.systemPackages = with pkgs; [ mesos ] ++ (optionals isSlave [ spark ]);
      }
    );
}
