package portage;

use Rex -base;

desc "Set gentoo-portage mirror (--sync_host=)";
task "mirror", group => "servers", make {
	needs main "root" || die "Cannot gain root access";

	file "/etc/portage/repos.conf",
		ensure => "directory";
	file "/etc/portage/repos.conf/gentoo.conf",
		content => template('templates/gentoo.conf');
};

desc "Set gentoo-portage git mirror";
task "git", group => "servers", make {
	needs main "root" || die "Cannot gain root access";

	file "/usr/portage",
		ensure => "absent";
	file "/etc/portage/repos.conf",
		ensure => "directory";
	file "/etc/portage/repos.conf/gentoo.conf",
		content => template('@gentoogit');
};

desc "Set BINHOST (--arch= or detect)";
task "binhost", group => "servers", make {
	needs main "root" || die "Cannot gain root access";

	my $params = shift;
	my %sysinf = get_system_information;
	my $architecture = $sysinf{architecture};
	my $arch;
	if (defined $params->{arch}) {
		$arch = $params->{arch}
	} elsif ($architecture eq 'x86_64') {
		$arch = "amd64"
	} elsif ($architecture eq "arm") {
		$arch = "armv7a"
	} else {
		die "Unsupported architecture: $architecture"
	}
	append_or_amend_line "/etc/portage/make.conf",
		line => 'PORTAGE_BINHOST="https://'.$arch.'.0xdc.io/"',
		regexp => qr{^PORTAGE_BINHOST=};
	append_if_no_such_line "/etc/portage/make.conf",
		line => 'FEATURES="$FEATURES getbinpkg"',
		regexp => qr{getbinpkg};
};

desc "Install portage-sync timer";
task "sync", group => "servers", make {
	needs main "root" || die "Cannot gain root access";

	run "systemctl-daemon-reload",
		command => "systemctl daemon-reload",
		only_notified => TRUE;

	file "/etc/systemd/system/portage-sync.service",
		content => template('@sync.service'),
		on_change => sub { notify "run", "systemctl-daemon-reload" };
	file "/etc/systemd/system/portage-sync.timer",
		content => template('@sync.timer'),
		on_change => sub { notify "run", "systemctl-daemon-reload" };

	service "portage-sync.timer", ensure => "started";
};

# https://wiki.gentoo.org/wiki/Handbook:AMD64/Portage/Advanced#Per-package_environment_variables
desc "Setup per-package CFLAGS for lowmem";
task "slow", group => "servers", make {
	needs main "root" || die "Cannot gain root access";
	file "/etc/portage/env",
		ensure => "directory";
	file "/etc/portage/env/extreme-slow",
		content => qq|CFLAGS="\$CFLAGS --param ggc-min-expand=0 --param ggc-min-heapsize=4096 -fno-inline"\nCXXFLAGS="\$CFLAGS"|;
	file "/etc/portage/env/medium-slow",
		content => qq|CFLAGS="\$CFLAGS --param ggc-min-expand=10 --param ggc-min-heapsize=8192"\nCXXFLAGS="\$CFLAGS"|;
	file "/etc/portage/env/light-slow",
		content => qq|CFLAGS="\$CFLAGS --param ggc-min-expand=20 --param ggc-min-heapsize=32768"\nCXXFLAGS="\$CFLAGS"|;
};

desc "Fix perl issues";
task "perl", group => "servers", make {
	needs main "root" || die "Cannot gain root access";

	Rex::Logger::info("Fixing perl...", "warn");
	run "(qlist -IC 'virtual/perl*'; qlist -IC 'dev-perl/*') | xargs emerge -1 dev-lang/perl texinfo";
};

1;

__DATA__
@gentoogit
[DEFAULT]
main-repo = gentoo

[gentoo]
location = /usr/portage
sync-type = git
sync-uri = https://github.com/gentoo/gentoo
auto-sync = yes
@end

@sync.service
[Unit]
Description=Sync portage trees

[Service]
ExecStart=/usr/sbin/emaint sync -a
@end

@sync.timer
[Unit]
Description=Sync portage trees periodically

[Timer]
OnBootSec=6h
OnUnitActiveSec=24h
AccuracySec=6h
#RandomizedDelaySec=10min

[Install]
WantedBy=timers.target
@end
