package App::GitDeploy::Role::Run;

# ABSTRACT: Role to provide local and remote run commands

use 5.012;
use strict;
use warnings;
use Try::Tiny;
use File::chdir;
use Term::ANSIColor;
use App::GitDeploy::SSH;
use IPC::Cmd ();
use IPC::System::Simple qw(system systemx capture capturex);

use Role::Tiny;

our $VERSION = '1.09';
our $config;

sub run {
    my ($self,$opts) = @_;

    if ( exists $opts->{host} ) {
        $self->_remote_run($opts);
    } else {
        $self->_local_run($opts);
    }
}

sub _remote_run {
    my ($self, $opts) = @_;

    my $config = $self->app->config;
    my $cmd = qq{
        export GIT_DIR="@{[ $config->remote_url->path ]}";
        export GIT_WORK_TREE="@{[ $config->deploy_dir->path ]}";
        cd @{[ $opts->{host}->path ]};
        $opts->{cmd} };

    if ( $opts->{host}->scheme eq 'ssh' ) {
        my $ssh = App::GitDeploy::SSH->new( uri => $opts->{host} );

        if ( $opts->{if_exists} ) {
            my $cmd = ( split /\s+/, $opts->{cmd} )[0];
            my $test_cmd = qq{
                cd @{[ $opts->{host}->path ]};
                test -x $cmd };
            return unless $ssh->test($test_cmd);
        }

        $ssh->run($cmd)
          or die color('red')
          . "Error running '$cmd on remote'\n"
          . color('reset') . "\n";

    } else {
        local $CWD = $opts->{host}->path;

        die "Remote path doesn't appear to exist"
          unless -d $opts->{host}->path;

        local_run( { $opts, cmd => $cmd } );
    }

}

sub _local_run {
    my ($self,$opts) = @_;

    my $config = $self->app->config;
    my $buffer;

    if ( $opts->{if_exists} ) {
        my ( $cmd, undef ) = split / /, $opts->{cmd}, 2;
        return unless IPC::Cmd::can_run($cmd);
    }

    say color('grey12') . "running [$opts->{cmd}]" . color('reset');
    try {
        system( $opts->{cmd} );
    }
    catch {
        die color('red')
          . "Error running '$opts->{cmd}'\n"
          . $_ . "\n"
          . color('reset') . "\n";
    };
}

1;
