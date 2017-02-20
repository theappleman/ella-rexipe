package dev;

use Rex -base;

task "dotd", make {
	my $params = shift;
	my $root = $params->{root} || 0;
	my $conf = $params->{conf} || die 'Required parameter: conf';
	my $line = $params->{line} || die 'Required parameter: line';

	if (!is_file($conf)) {
		file $conf,
			ensure => "directory";
		$conf .= "/zz-rex";
		file $conf,
			ensure => "present";
	}
	append_if_no_such_line $conf, $line;
}, { dont_register => TRUE };

desc "Install mysql";
task "mysql", make {
	needs main "root" || die "Cannot gain root access";
	pkg "virtual/mysql", ensure => "present";

	run "/usr/share/mysql/scripts/mysql_install_db",
		cwd => "/usr",
		creates => "/var/lib/mysql/ibdata1";

	file "/etc/mysql/zz-mybind.cnf",
		"ensure" => "absent";
	file "/etc/mysql/mybind.cnf",
		content => template('@mybind.cnf'),
		on_change => sub { service "mysqld" => "restart" };
	delete_lines_according_to qr{^bind-address}, "/etc/mysql/my.cnf",
		on_change => sub { service "mysqld" => "restart" };
	service "mysqld", ensure => "started";

	my $pwgen;
	LOCAL {
		$pwgen = run "pwgen -s";
	};

	run "mysqladmin password $pwgen";
	file "/root/.my.cnf",
		content => template('@my.cnf', password => $pwgen);

	run q|mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"|;
	run q|mysql -e "DELETE FROM mysql.user WHERE User=''"|;
	run q|mysql -e "DROP DATABASE IF EXISTS test"|;
	run q|mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"|;
	run q|mysql -e "FLUSH PRIVILEGES"|;
}, { dont_register => TRUE };

desc "Install go";
task "go", make {
	needs main "root" || die "Cannot gain root access";
	pkg "dev-lang/go", ensure => "present";
}, { dont_register => TRUE };

desc "Install nodejs";
task "nodejs", make {
	needs main "root" || die "Cannot gain root access";
	run_task "dev:dotd", on => connection->server, params => {
		root => 1,
		conf => "/etc/portage/package.accept_keywords",
		line => "=net-libs/http-parser-2.6.2 ~arm",
	};
	run_task "dev:dotd", on => connection->server, params => {
		root => 1,
		conf => "/etc/portage/package.accept_keywords",
		line => "=dev-libs/libuv-1.9.1 ~arm",
	};
	run_task "dev:dotd", on => connection->server, params => {
		root => 1,
		conf => "/etc/portage/package.accept_keywords",
		line => "=net-libs/nodejs-6.2.1 ~arm",
	};
	run_task "dev:dotd", on => connection->server, params => {
		root => 1,
		conf => "/etc/portage/package.use",
		line => "dev-libs/openssl -bindist",
	};
	run_task "dev:dotd", on => connection->server, params => {
		root => 1,
		conf => "/etc/portage/package.use",
		line => "net-misc/openssh -bindist",
	};
	pkg "net-libs/nodejs", ensure => "present";
}, { dont_register => TRUE };

desc "Install elixir";
task "elixir", make {
	needs main "root" || die "Cannot gain root access";
	run_task "dev:dotd", on => connection->server, params => {
		root => 1,
		conf => "/etc/portage/package.accept_keywords",
		line => "=dev-lang/erlang-18.3 ~arm",
	};
	run_task "dev:dotd", on => connection->server, params => {
		root => 1,
		conf => "/etc/portage/package.accept_keywords",
		line => "=dev-lang/elixir-1.2.5 **",
	};
	pkg "dev-lang/elixir", ensure => "present";
}, { dont_register => TRUE };

desc "Install vim";
task "vim", make {
	needs main "root" || die "Cannot gain root access";
	pkg "app-editors/vim", ensure => "present";
}, { dont_register => TRUE };

desc "Install dev and language tools";
batch "dev", "dev:vim", "dev:go", "dev:elixir", "dev:nodejs", "dev:mysql";

1;

__DATA__
@mybind.cnf
[mysqld]
bind-address = ::
@end

@my.cnf
[client]
user=root
password=<%= $password %>
@end
