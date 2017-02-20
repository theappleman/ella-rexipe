package ;

use Rex -base;

desc "Install ";
task "install", make {
	needs main "root" || die "Cannot gain root access";
	pkg "", ensure => "latest";
};

1;
