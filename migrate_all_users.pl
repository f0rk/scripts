#!/usr/bin/perl

use strict;
use warnings;

my $source_server = $ARGV[0];

my $help = <<EHELP
usage: sudo perl $0 source_server

desc: this script will copy users from one Linux system to another.

params:
source_server: the address of the server to copy users from
EHELP
;

if(!defined($source_server)) {
    print "source server must be defined\n";
    print $help;
    exit(1);
}

my $name = getgrent();
if($name ne "root") {
    print "you must run this script as root! exiting...\n";
    exit(1);
}

print "copying user accounts and passwords from $source_server\n";

print "backing up user acccounts and passwords on this machine\n";
if(!-d "/tmp/backup") {
    mkdir("/tmp/backup") || die "could not create backup dir $!\n";
}
`cp /etc/passwd /etc/shadow /etc/group /etc/gshadow /tmp/backup`;

print "copying user account and passwords from $source_server\n";
`scp $source_server:/etc/passwd /tmp/passwd`;
`scp $source_server:/etc/group /tmp/group`;
`scp $source_server:/etc/shadow /tmp/shadow`;
`scp $source_server:/etc/gshadow /tmp/gshadow`;

`cp /tmp/passwd /etc/passwd`;
`cp /tmp/group /etc/group`;
`cp /tmp/shadow /etc/shadow`;
`cp /tmp/gshadow /etc/gshadow`;

print "cleaning up\n";
unlink("/tmp/passwd");
unlink("/tmp/group");
unlink("/tmp/shadow");
unlink("/tmp/gshadow");

print "done!\n";
exit(0);

print "migrating /home\n";
`rsync -av --delete $source_server:/home/ /home/`;

print "done!\n";
