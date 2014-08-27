# Mesos cluster configuration:
# - Find zookeeper nodes
# - Find mesos master nodes
# - Add firewall rules

with import <nixpkgs/lib>;

{
  defaults = { config, pkgs, nodes, ... }:
    let
      isMaster = config.services.mesos.master.enable;
      isSlave = config.services.mesos.slave.enable;
      mapNodesToList = f: mapAttrsToList f nodes;
    in let
      mapNodesToString = f: concatStrings (mapNodesToList f);
    in mkIf (isMaster || isSlave) (
      let

        zkServers = concatStringsSep  "," (remove "" 
          (mapNodesToList (nodeId: node:
            optionalString node.config.services.zookeeper.enable "${nodeId}:2181"
          ))
        );

        allowSlave2Slave = mapNodesToString (nodeId: node:
            let mesos = node.config.services.mesos; in
              optionalString mesos.slave.enable ''
                iptables -A nixos-fw -s ${nodeId} -p tcp -m comment --comment "Allow mesos slave ${nodeId}" -j ACCEPT
              ''
        );

        allowSlave2Master = mapNodesToString (nodeId: node:
            let mesos = node.config.services.mesos; in
              optionalString mesos.slave.enable ''
                iptables -A nixos-fw -s ${nodeId} -p tcp --dport 5050 -m comment --comment "Allow mesos slave ${nodeId}" -j ACCEPT
              ''
        );

        allowMaster2Slave = mapNodesToString (nodeId: node:
            let mesos = node.config.services.mesos; in
              optionalString mesos.master.enable ''
                iptables -A nixos-fw -s ${nodeId} -p tcp --dport 5051 -m comment --comment "Allow mesos master ${nodeId}" -j ACCEPT
              ''
        );

        allowMaster2Master = mapNodesToString (nodeId: node:
            let mesos = node.config.services.mesos; in
              optionalString mesos.master.enable ''
                iptables -A nixos-fw -s ${nodeId} -p tcp --dport 5050 -m comment --comment "Allow mesos master ${nodeId}" -j ACCEPT
              ''
        );

        masterCount = count (x: x.config.services.mesos.master.enable) (attrValues nodes);

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

        networking.firewall.extraCommands = (
          (optionalString isSlave (allowMaster2Slave + allowSlave2Slave))
          + (optionalString isMaster (allowMaster2Master + allowSlave2Master))
        );

        environment.systemPackages = with pkgs; [ mesos ] ++ (optionals isSlave [ spark ]);
      }
    );
}
