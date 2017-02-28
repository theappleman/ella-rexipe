# enable new Features
use Rex -feature => '1.0';

# set your username
set user => "root";

# set parallelism to max
set parallelism => "max";

# enable key-based authentication
set -keyauth;

# put your server in this group
set group => "servers" => "ella[1..3].0xdc.host", "ella0.0xdc.host" => { platform => "hdmi"};

task "root", make {
	my $user = run "whoami";

	if ($user eq "root") {
		return 1;
	} else {
		sudo TRUE;
		$user = run "whoami";
		if ($user eq "root") {
			return 1;
		} else {
			die "Could not gain root privileges";
		}
	}
}, { dont_register => TRUE };

desc "Run a shell command (--shell=)";
task "shell", make {
	my $params = shift;

	if (defined($params->{root})) {
		needs main "root" || die "Could not elevate privileges";
	}
	my $cmd = $params->{shell} ne 1 ? $params->{shell} : "whoami";

	run $cmd, sub {
		my ($stdout, $stderr) = @_;
		my $server = Rex::get_current_connection()->{server};
		say "[$server] $cmd => $stdout\n";
		say "[$server] => $stderr\n";
	}
};

desc "Install a package";
task "install", make {
	needs main "root" || die "Could not elevate privileges";
	my $params = shift;
	my $pkg = (defined($params->{pkg})) ? $params->{pkg} : die("No package given");

	pkg $pkg, ensure => ($params->{state} || "latest");
};

desc "Update package directory";
task "sync", make {
	parallelism '1';

	needs main "root" || die "Could not gain root privileges";
	update_package_db;
};

desc "Update system packages";
task "update", make {
	needs main "root" || die "Could not gain root privileges";
	update_system;
};

desc "Get uptime of server";
task "uptime", sub {
   say connection->server . ": " . run "uptime";
};

task "sys", make {
	my $params = shift;
	my $sys = $params->{sys};
	if ($sys eq "proc") {
		use Rex::Inventory::Proc;
		use Data::Dumper;
		say(Dumper(Rex::Inventory::Proc->new));
	} elsif ($sys ne 1) {
		my %sysinf = get_system_information;
		my $server = connection->server;
		say "[$server] $sys=$sysinf{$sys}";
	} else {
		dump_system_information;
	}
};

# now load every module via ,,require''
require Rex::Test;
require ella;
require kexec;
require portage;
require scw;
require dev;
require overlay;

desc "Minimal setup to upgrade scaleway servers";
batch "scw", qw|
	scw:binpkg
	scw:firstboot
	portage:perl
	overlay:install
	overlay:profile
	ella:systemd_keywords
	ella:systemd
	update
|;

desc "Run scw batch";
task "scw", make {
	my $params = shift;
	my $arch = $params->{arch} || "arm";
	run_batch "scw", on => connection->server, params => { profile => "0xdc:$arch", init => 1 }
};
