package overlay;

use Rex -base;
use Rex::Commands::SCM;

set repository => "0xdc",
	url => 'https://github.com/0xdc/overlay';

desc "Install overlay";
task "install", make {
	needs main "root" || die "Cannot gain root access";
	pkg "dev-vcs/git", ensure => "present";

	checkout "0xdc",
		path => "/var/db/repos/0xdc";
	file "/etc/portage/repos.conf",
		ensure => "directory";
	file "/etc/portage/repos.conf/0xdc.conf",
		content => cat "/var/db/repos/0xdc/metadata/repos.conf";
};

desc "Set a profile";
task "profile", make {
	needs main "root" || die "Cannot gain root access";

	my $params = shift;

	if (defined $params->{profile}) {
		unless (is_symlink "/etc/portage/make.profile") {
			file "/etc/portage/make.profile",
				ensure => "absent";
		}
		run "eselect profile set $params->{profile}";
	} else {
		run "eselect profile list", sub {
			my ($stdout, $stderr) = @_;
			my $server = Rex::get_current_connection()->{server};
			say "[$server] $stdout\n";
		};
	}
};

1;
