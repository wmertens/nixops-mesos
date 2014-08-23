nixops-mesos
============

A deployment of mesos via NixOps

Lots to do; first step: get a working zookeeper. The zookeeper branch of https://github.com/nathan-gs/nixpkgs doesn't quite work yet.

To test, clone Nathan's repo, checkout zookeeper branch and run

    nixops create -d zookeeper zk.nix
    NIX_PATH=nixpkgs=path_to_repo nixops deploy

