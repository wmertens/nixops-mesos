# Zookeeper cluster configuration:
# - Add other servers to configuration
# - Add firewall rules

with import <nixpkgs/lib>;

{
  defaults = 
    { config, pkgs, nodes, ... }:
      let
        zkServers = concatStrings (
          mapAttrsToList (hostId: node:
            let zk = node.config.services.zookeeper; in
              if zk.enable then ''
                server.${toString zk.id} = ${hostId}:2888:3888
              '' else ""
          ) nodes
        );

        allowOthers = concatStrings (
          mapAttrsToList (hostId: node:
            let zk = node.config.services.zookeeper; in
              if zk.enable then ''
                iptables -A nixos-fw -s ${hostId} -p tcp -m multiport --dports 2888,3888 -m comment --comment "Allow zookeeper node ${hostId}" -j ACCEPT
              '' else ""
          ) nodes
        );

      in
        mkIf config.services.zookeeper.enable
        {
            services.zookeeper = {
              servers = zkServers;
            };
            networking.firewall = {
              allowedTCPPorts = [ 2181 ];
              extraCommands = allowOthers;
            };
            # Client binaries
            environment.systemPackages = with pkgs; [ zookeeper ];
        };
}
