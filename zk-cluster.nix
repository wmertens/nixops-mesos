# Zookeeper cluster configuration:
# - Add other servers to configuration
# - Add firewall rules

with import <nixpkgs/lib>;

{
  defaults = { config, pkgs, nodes, ... }:
    let
      mapNodesToList = f: mapAttrsToList f nodes;
    in let
      mapNodesToString = f: concatStrings (mapNodesToList f);
    in let

      zkServers = mapNodesToString (nodeId: node:
        let zk = node.config.services.zookeeper; in
        optionalString zk.enable "server.${toString zk.id} = ${nodeId}:2888:3888\n"
      );

      allowOtherMasters = mapNodesToString (nodeId: node:
        let zk = node.config.services.zookeeper; in
        optionalString zk.enable ''
          iptables -A nixos-fw -s ${nodeId} -p tcp -m multiport --dports 2888,3888 -m comment --comment "zk: allow master ${nodeId}" -j ACCEPT
        ''
      );

      allowAll = mapNodesToString (nodeId: node:
        let zk = node.config.services.zookeeper; in
        optionalString zk.enable ''
          iptables -A nixos-fw -s ${nodeId} -p tcp --dport ${toString zk.port} -m comment --comment "zk: allow node ${nodeId}" -j ACCEPT
        ''
      );

    in
      mkIf config.services.zookeeper.enable
      {
          services.zookeeper = {
            servers = zkServers;
          };
          networking.firewall = {
            # We allow other masters to master ports and other nodes to zk port, no-one else
            extraCommands = allowOtherMasters + allowAll;
          };
          # Client binaries
          environment.systemPackages = with pkgs; [ zookeeper ];
      };
}
