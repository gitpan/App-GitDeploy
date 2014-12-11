package App::GitDeploy::SSH;

use 5.012;
use strict;
use warnings;
use Moo;
use Net::OpenSSH;
use Expect;
use Term::ReadKey;
use Term::ANSIColor;
use IO::Prompter;

# use namespace::sweep;

has 'ssh' => ( is => 'ro', builder => '_ssh_builder', lazy => 1, );
has 'uri'         => ( is => 'ro', required => 1, );
has 'failure_msg' => ( is => 'ro', default  => 'SSH_CMD_FAILED' );

sub _ssh_builder {
    my ($self) = @_;

    my $ssh = Net::OpenSSH->new(
        $self->uri->host,
        user     => $self->uri->user,
        port     => $self->uri->port,
        password => $self->uri->password,
    );
    $ssh->error
      and die color('red')
      . "Can't ssh to host: "
      . $ssh->error
      . color('reset');

    # $ssh->test( 'cd', $self->uri->path )
    #   or die "unable to cd into the remote dir: "
    #   . $self->uri->path . "\n"
    #   . $ssh->error;

    return $ssh;
}

sub run {
    my ( $self, $cmd ) = @_;

    $cmd .= sprintf q{ || echo "%s" }, $self->failure_msg;
    say color('grey12') . "SSH running [$cmd]" . color('reset');
    my $ssh = $self->ssh;
    my ( $pty, $pid ) =
      $ssh->open2pty( { stderr_to_stdout => 1, tty => 1 }, $cmd )
      or die color('red')
      . "Error executing on remote: "
      . $ssh->error
      . color('reset');

    my $expect = Expect->init($pty);
    my $failed = 0;
    $expect->log_stdout(1);
    $expect->expect(
        undef,
        [
            qr/\[sudo\] password for (.*): / => sub {
                my $exp      = shift;
                my $password = get_pw();
                $exp->send("$password\n");
                exp_continue;
            }
        ],
        [
            qr/@{[ $self->failure_msg ]}/ => sub {
                my $exp = shift;
                $failed++;
                exp_continue;
            }
        ],
    );

    warn "Exit status is: " . ( $expect->exitstatus // 'undef' ) . "\n";

    return !$failed;
}

sub get_pw {
    my $prompt    = shift;
    my $passwords = {};
    return $passwords->{$prompt} //= prompt $prompt, -echo => '*';
}

sub test {
    my ( $self, $cmd ) = @_;

    say color('grey8') . "SSH testing [$cmd]" . color('reset');
    return $self->ssh->test($cmd);
}

1;

__END__

=pod

=head1 NAME

App::GitDeploy::SSH

=head1 VERSION

version 1.09

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
