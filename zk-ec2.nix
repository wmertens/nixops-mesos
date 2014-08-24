
{
  defaults =
    { config, pkgs, ... }:
    { imports = [ ./ec2-info.nix ];
      deployment.targetEnv = "ec2";
      deployment.ec2.region = pkgs.lib.mkDefault "eu-west-1";
      deployment.ec2.instanceType = "m1.small";
    };
    
}
