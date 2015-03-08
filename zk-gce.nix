
{
  defaults =
    { config, pkgs, ... }:
    with pkgs.lib;
    {
      imports = [ ./gce-info.nix ];
      deployment = {
        targetEnv = "gce";

        gce = {
          region = mkDefault "europe-west1-b";
          instanceType = mkDefault "n1-standard-2";
          scheduling.automaticRestart = true;
          scheduling.onHostMaintenance = "MIGRATE";
	};
      };
    };
}
