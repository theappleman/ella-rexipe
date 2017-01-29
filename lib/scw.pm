package scw;

use Rex -base;

desc "[firstboot] update the system to be more modern";
task "firstboot", groups => "scw", make {
	needs main "root" || die "Cannot gain root access";
	pkg "portage", ensure => "latest";
	pkg "gcc", ensure => "latest",
		on_change => sub {
			run_task "scw:gcc", on => connection->server;
		};
	Rex::Logger::info("Updating system...");
	run 'emerge -uD @system';
	pkg '@preserved-rebuild', ensure => "latest";
	pkg [qw|nss-myhostname python:3.3 gcc:4.8.5|], ensure => "absent";
};

desc "Update gcc config to latest compiler";
task "gcc", groups => "scw", make {
	run "test \"\$ccpro\" && test \"\$(gcc-config -c)\" != \"\$ccpro\" && gcc-config \$ccpro",
		env => { ccpro => run "gcc-config -l | awk 'END{print \$2}'" };
	run "env-update";
	run "emerge -1q libtool";
}, { dont_register => TRUE };

desc "Configure the building of binpkgs";
task "binpkg", groups => "scw", make {
	append_if_no_such_line "/etc/portage/make.conf",
		'FEATURES="$FEATURES buildpkg binpkg-multi-instance"';
};

desc "nginx vhost for serving packages";
task "vhost", groups => "scw", make {
	file "/etc/nginx/conf.d/packages.conf",
		ensure => "absent";
	file "/etc/nginx/vhosts.d/packages.conf",
		on_change => sub { service nginx => "reload" },
		content => template('@pkgs');
};

1;

__DATA__

@pkgs
server {
	listen 0.0.0.0:80;
	server_name _;

	location / {
		alias /usr/portage/packages/;
	}

	include acme-challenge.conf;
}
@end
