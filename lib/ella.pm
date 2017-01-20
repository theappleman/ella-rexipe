package ella;

use Rex -base;
use Rex::Commands::SCM;

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

desc "Expand last partition to max";
task "fdisk", group => "servers", make {
	my @fdisk = run "fdisk -l /dev/mmcblk0";
	my @disk = split " ", $fdisk[0];
	my $sectors = $disk[6];
	my @part = split " ", pop @fdisk;
	my ($start, $end) = ($part[1], $part[3]);

	my $eDiff = ($sectors - $start);
	my $rDiff = (($sectors - $start) - $end);

	unless ($rDiff == 0) {
		my @sfdisk = run "sfdisk --dump /dev/mmcblk0";
		my $sfdisk = join "\n", @sfdisk;
		file "/root/mmcblk0.mbr",
			content => $sfdisk =~ s/$sectors/$eDiff/r;

		run "sfdisk --force /dev/mmcblk0 < /root/mmcblk0.mbr";
		run "partx -u /dev/mmcblk0";
		run "resize2fs /dev/mmcblk0p2";
	}
};

set repository => "epython",
	url => "https://github.com/mesham/epython";

desc "Install epython interpreter";
task "epython", group => "servers", make {
	pkg "dev-vcs/git", ensure => "present";
	checkout "epython",
		on_change => sub {
			run "make CC=armv7a-hardfloat-linux-gnueabi-gcc",
				cwd => "/usr/src/epython";
		},
		path => "/usr/src/epython";
	run "make CC=armv7a-hardfloat-linux-gnueabi-gcc",
		cwd => "/usr/src/epython",
		creates => "/usr/src/epython/epython-host";
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
