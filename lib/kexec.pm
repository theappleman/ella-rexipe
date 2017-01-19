package kexec;

use Rex -base;

desc "Setup kexec-target";
task "setup", make {
	pkg "kexec-tools", ensure => "present";

	file '/etc/systemd/system/kexec-load@.service',
		content => template('@kexec'),
		owner => "root",
		group => "root";
};

1;

__DATA__

@kexec
[Unit]
Description=load %i kernel into the current kernel
Documentation=man:kexec(8)
DefaultDependencies=no
Before=shutdown.target umount.target final.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/kexec -l /boot/kernel-%i --initrd=/boot/initramfs-%i --reuse-cmdline

[Install]
WantedBy=kexec.target
@end
