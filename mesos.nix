{
	mesos-master = {
		networking.firewall.enable = false;
		services.mesos = {
			master = {
				enable = true;
				zk = "zk://zk-0:2181,zk-1:2181,zk-2:2181/mesos";
				quorum=0;
			};
		};
	};
	mesos-slave = {
		networking.firewall.enable = false;
		services.mesos = {
			slave = {
				enable = true;
				master = "zk://zk-0:2181,zk-1:2181,zk-2:2181/mesos";
			};
		};

	};
}
