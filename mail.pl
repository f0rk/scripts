#!/usr/bin/perl

use strict;
use warnings;
use MIME::Lite;

my $usage =  qq{usage: mail.pl from\@addr to\@addr "subject" < message.txt\n};

die $usage if !defined($ARGV[0]);
die $usage if !defined($ARGV[1]);
die $usage if !defined($ARGV[2]);

my $msg = MIME::Lite->new(
    From     => $ARGV[0],
    To       => $ARGV[1],
    Subject  => $ARGV[2],
    Data     => join('', <>),
);

$msg->send();

