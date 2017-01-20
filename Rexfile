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
task "shell", group => "servers", make {
	my $params = shift;

	if (defined($params->{root})) {
		needs main "root" || die "Could not elevate privileges";
	}
	my $cmd = (defined($params->{shell})) ? $params->{shell} : "whoami";

	run $cmd, sub {
		my ($stdout, $stderr) = @_;
		my $server = Rex::get_current_connection()->{server};
		say "[$server] $stdout\n";
	}
};

desc "Install a package";
task "install", group=> "servers", make {
	needs main "root" || die "Could not elevate privileges";
	my $params = shift;
	my $pkg = (defined($params->{pkg})) ? $params->{pkg} : die("No package given");

	pkg $pkg, ensure => "latest";
};

desc "Update package directory";
task "sync", group => "servers", make {
	parallelism '1';

	needs main "root" || die "Could not gain root privileges";
	update_package_db;
};

desc "Update system packages";
task "update", group => "servers", make {
	needs main "root" || die "Could not gain root privileges";
	update_system;
};


# now load every module via ,,require''
require Rex::Test;
require ella;
require kexec;

