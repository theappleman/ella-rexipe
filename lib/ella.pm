package ella;

use Rex -base;

desc "Get uptime of server";
task "uptime", group => 'servers', sub {
   say connection->server . ": " . run "uptime";
};

desc "Convert to systemd";
task "systemd", group => 'servers', make {
	if ( is_installed("systemd") ) {
		say "systemd is installed";
	} else {
		if (is_installed("sys-fs/udev")) {
			pkg "sys-fs/udev", ensure => "absent";
			pkg "virtual/udev", ensure => "absent";
		}

		if (is_symlink("/etc/portage/make.profile")) {
			unlink("/etc/portage/make.profile");
			file "/etc/portage/make.profile",
				ensure => "directory";
			file "/etc/portage/make.profile/parent",
				content => template('@profile');
		}
		pkg "sys-apps/systemd", ensure => "latest";
	}
	if (!is_symlink("/sbin/init")) {
		rename "/sbin/init", "/sbin/init.openrc";
		symlink "/usr/lib/systemd/systemd", "/sbin/init";
	}
	file "/etc/systemd/system/getty.target.wants",
		ensure => "directory";
	file "/etc/systemd/system/multi-user.target.wants",
		ensure => "directory";

	symlink '/usr/lib/systemd/system/systemd-networkd.service',
		'/etc/systemd/system/multi-user.target.wants/systemd-networkd.service';
	symlink '/usr/lib/systemd/system/systemd-timesyncd.service',
		'/etc/systemd/system/multi-user.target.wants/systemd-timesyncd.service';

	symlink '/usr/lib/systemd/system/sshd.service',
		'/etc/systemd/system/multi-user.target.wants/sshd.service';
	symlink '/usr/lib/systemd/system/serial-getty@.service',
		'/etc/systemd/system/getty.target.wants/serial-getty@ttyPS0.service';

	file "/etc/systemd/network/eth0.network",
		content => template('@eth0');
};

desc "Set the date from the local system";
task "date", group => "servers", make {
	my $date = '';
	LOCAL {
		$date = run "date +%s"
	};
	run "date -s\@$date";
};

desc "Set systemd hostname";
task "hostname", group => "servers", make {
	file "/etc/hostname",
		content => connection->server;
};

desc "Get MBR partition scheme";
task "fdisk", group => "servers", make {
	file "/root/mmcblk0.mbr",
		content => (run "sfdisk --dump /dev/mmcblk0").join("\n");
};

1;

__DATA__
@profile
gentoo:default/linux/arm/13.0/armv7a
gentoo:targets/systemd
@end

@eth0
[Match]
Name=eth0

[Network]
DHCP=yes
@end
