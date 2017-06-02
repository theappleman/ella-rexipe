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

	delete_lines_according_to qr{(sys-apps|sys-devel|dev-lang)/.*},
		"/var/lib/portage/world";

	Rex::Logger::info("Updating system...");
	run 'emerge -uD @system';
	pkg '@preserved-rebuild', ensure => "latest";
	pkg "nss-myhostname", ensure => "absent";
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
	append_if_no_such_line "/etc/portage/make.conf",
		q|EMERGE_DEFAULT_OPTS="$EMERGE_DEFAULT_OPTS --buildpkg-exclude 'virtual/* sys-kernel/*-sources sys-devel/gcc sys-devel/libtool'"|;
};

desc "nginx vhost for serving packages (--host=)";
task "vhost", groups => "scw", make {
	my $params = shift;

	my $ssl = is_file("/var/lib/acme/live/" . $params->{host} . "/privkey");

	file "/etc/nginx/vhosts.d/packages.conf",
		on_change => sub { service nginx => "reload" },
		content => template('@pkgs',
			host => $params->{host},
			ssl => $ssl,
		);
};

1;

__DATA__

@pkgs
server {
	listen 0.0.0.0:80;
	listen [::]:80;
	include acme-challenge.conf;

<% if ($ssl) { %>
	server_name <%= $host %>;
	return 301 https://<%= $host %>$request_uri;
}

server {
	listen 0.0.0.0:443 ssl http2;
	listen [::]:443 ssl http2;
	server_name <%= $host %>;
	ssl_certificate /var/lib/acme/live/<%= $host %>/fullchain;
	ssl_certificate_key /var/lib/acme/live/<%= $host %>/privkey;
<% } elsif ($host) { %>
	server_name <%= $host %>;
<% } else { %>
	server_name _;
<% } %>

	location / {
		alias /usr/portage/packages/;
	}
}
@end
