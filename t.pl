#!/usr/bin/env perl

use strict;
use warnings;
use Net::OpenSSH;
use Expect;
use Term::ReadKey;

my $cmd = q{sleep 3; sudo -k ; sudo -p '[sudo] password for mg: ' echo hi};

my $ssh = Net::OpenSSH->new('localhost');
$ssh->error and die "Can't ssh to host: " . $ssh->error;

my ( $pty, $pid ) = $ssh->open2pty( { stderr_to_stdout => 1, tty => 1 }, $cmd )
  or die "Error executing on remote: " . $ssh->error;

my $expect = Expect->init($pty);
$expect->log_stdout(1);
$expect->expect(
    60,
    [
        qr/\[sudo\] password for (.*):/ => sub {
            my $exp = shift;
            my $password = get_pw();
            $exp->send("$password\n");
            exp_continue;
          }
    ],
);

sub get_pw {
    my $prompt = shift;

    $|++;
    print $prompt if defined $prompt;

    ReadMode('noecho');
    ReadMode('raw');

    my $pass = '';
    while (1) {
        my $c;
        1 until defined( $c = ReadKey(-1) );
        exit if ord($c) == 3;    # ctrl-c
        last if $c eq "\n";
        print "*";
        $pass .= $c;
    }
    print "\n";

    END { ReadMode('restore'); }

    return $pass;
}
