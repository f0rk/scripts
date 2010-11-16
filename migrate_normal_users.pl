#!/usr/bin/perl

use strict;
use warnings;

my $source_ugid_limit = $ARGV[0];
my $source_ugid_max = $ARGV[1];
my $source_server = $ARGV[2];
my $dest_ugid_limit = $ARGV[3];

my $help = <<EHELP
usage: sudo perl $0 source_ugid_limit source_ugid_max source_server dest_ugid_limit

desc: this script will copy users from one Linux system to another.
It is designed to only copy non-admin users.

params:
source_ugid_limit: the lowest uid/gid to start copying users/groups from
source_ugid_max: the max uid/gid to copy
source_server: the address of the server to copy users from
dest_ugid_limit: the lowest non-admin uid/gid
EHELP
;

if(!defined($source_ugid_limit) || $source_ugid_limit !~ /^\d+$/) {
    print "source user/group id limit must be a number\n";
    print $help;
    exit(1);
}
if(!defined($source_ugid_max) || $source_ugid_max !~ /^\d+$/) {
    print "source user/group id max must be a number\n";
    print $help;
    exit(1);
}
if(!defined($source_server)) {
    print "source server must be defined\n";
    print $help;
    exit(1);
}
if(!defined($dest_ugid_limit) || $dest_ugid_limit !~ /^\d+$/) {
    print "destination user/group id limit must be a number\n";
    print $help;
    exit(1);
}

my $ugid_trans = 0;
if($dest_ugid_limit > $source_ugid_limit) {
    $ugid_trans = $dest_ugid_limit - $source_ugid_limit;
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
`scp $source_server:/etc/passwd /tmp/passwd.$source_server`;
`scp $source_server:/etc/group /tmp/group.$source_server`;
`scp $source_server:/etc/shadow /tmp/shadow.$source_server`;
`scp $source_server:/etc/gshadow /tmp/gshadow.$source_server`;

my %current_users = ();
open(my $INP, '<', '/etc/passwd');
while(my $line = <$INP>) {
    my ($user, undef, undef, undef, undef, undef, undef) = split(/:/, $line);
    $current_users{$user} = 1;
}

my %current_groups = ();
open(my $ING, '<', '/etc/group');
while(my $line = <$ING>) {
    my ($group, undef, undef, undef) = split(/:/, $line);
    $current_groups{$group} = 1;
}

my %new_users = ();
open(my $INPASSWD, '<', "/tmp/passwd.$source_server") || die "could get remote /etc/passwd\n";
`cp /etc/passwd /tmp`;
open(my $PASSWD, '>>', "/tmp/passwd") || die "couldn't open local /etc/passwd\n";
while(my $line = <$INPASSWD>) {
    chomp($line);
    my ($user, $pass, $uid, $gid, $full, $home, $shell) = split(/:/, $line);

    if($uid < $source_ugid_limit || $uid >= $source_ugid_max) {
        next;
    }

    my $new_uid = $uid + $ugid_trans;
    my $new_gid = $gid + $ugid_trans;

    if(!defined($current_users{$user})) {
        print "copying entry for user $user to this machine\n";
        print $PASSWD "$user:$pass:$new_uid:$new_gid:$full:$home:$shell\n";
        $new_users{$user} = 1;
    }
}
close($INPASSWD);
close($PASSWD);
`cp /tmp/passwd /etc/passwd`;

my %new_groups = ();
open(my $INGROUP, '<', "/tmp/group.$source_server") || die "couldn't get remote /etc/group\n";
`cp /etc/group /tmp`;
open(my $GROUP, '>>', "/tmp/group") || die "couldn't open local /etc/group\n";
while(my $line = <$INGROUP>) {
    chomp($line);
    my ($group, $pass, $gid, $userlist) = split(/:/, $line);

    if($gid < $source_ugid_limit || $gid >= $source_ugid_max) {
        next;
    }

    my $new_gid = $gid + $ugid_trans;

    if(!defined($current_groups{$group})) {
        print "copying entry for group $group to this machine\n";
        print $GROUP "$group:$pass:$new_gid:$userlist\n";
        $new_groups{$group} = 1;
    }
}
close($INGROUP);
close($GROUP);
`cp /tmp/group /etc/group`;

open(my $INSHADOW, '<', "/tmp/shadow.$source_server") || die "couldn't get remote /etc/shadow\n";
`cp /etc/shadow /tmp`;
open(my $SHADOW, '>>', "/tmp/shadow") || die "couldn't open local /etc/shadow\n";
while(my $line = <$INSHADOW>) {
    my ($user, $pass, $last, $min, $max, $warn, $inactive, $expire) = split(/:/, $line);
    
    if(defined($new_users{$user})) {
        print "copying shadow entry for user $user to this machine\n";
        print $SHADOW $line;
    }
}
close($INSHADOW);
close($SHADOW);
`cp /tmp/shadow /etc/shadow`;

#group pass admins members
open(my $INGSHADOW, '<', "/tmp/gshadow.$source_server");
`cp /etc/gshadow /tmp`;
open(my $GSHADOW, '>>', "/tmp/gshadow");
while(my $line = <$INGSHADOW>) {
    my ($group, $pass, $admins, $members) = split(/:/, $line);

    if(defined($new_groups{$group})) {
        print "copying gshadow entry for group $group to this machine\n";
        print $GSHADOW $line;
    }
}
close($INGSHADOW);
close($GSHADOW);
`cp /tmp/gshadow /etc/gshadow`;

print "cleaning up\n";
unlink("/tmp/passwd.$source_server");
unlink("/tmp/group.$source_server");
unlink("/tmp/shadow.$source_server");
unlink("/tmp/gshadow.$source_server");
unlink("/tmp/passwd");
unlink("/tmp/group");
unlink("/tmp/shadow");
unlink("/tmp/gshadow");

print "done!\n";
exit(0);

print "migrating /home\n";
`rsync -av --delete $source_server:/home/ /home/`;

print "done!\n";
