{
	mesos-master = {
		services.mesos = {
			master = {
				enable = true;
				quorum=0;
			};
		};
	};
	mesos-slave = {
		services.mesos = {
			slave = {
				enable = true;
			};
		};

	};
}
