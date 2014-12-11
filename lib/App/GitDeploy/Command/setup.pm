package App::GitDeploy::Command::setup;

use 5.012;
use strict;
use warnings;
use Path::Class;
use App::GitDeploy::SSH;
use Role::Tiny::With;
use File::Path;

use App::GitDeploy -command;
with 'App::GitDeploy::Role::Run';

our $VERSION = '1.09';

sub opt_spec {
    return (
        # [ "app|a=s",    "The app to deploy", { default => '.' } ],
        # [ "remote|r=s", "The remote repos",  { default => 'production' } ],
        [ "work|w=s", "The work " ],
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    my $config = $self->app->validate_global_opts();
    return 1;
}

sub execute {
    my ( $self, $opt, $arg ) = @_;

    my $config = $self->app->config;
    my $ssh    = App::GitDeploy::SSH->new( uri => $config->remote_url );
    my $app    = $self->app->global_options->{app};
    my $remote = $self->app->global_options->{remote};

    # TODO: should $ssh->run be converted into $self->run?
    say "Creating the deployment repos: @{[ $config->remote_url ]}";
    $ssh->run( "git init --bare @{[ $config->remote_url->path ]}", );
    say "Creating the deployment work dit: @{[ $config->deploy_dir ]}";
    $ssh->run(
        "test -d @{[ $config->deploy_dir->path ]} || mkdir @{[ $config->deploy_dir->path ]}",
    );

    mkpath sprintf( 'deploy/%s/%s', $app, $remote ), { verbose => 1 };

    my $pr_file = file( sprintf 'deploy/%s/%s/post-receive', $app, $remote );
    if ( !-e $pr_file ) {
        say "Creating [$pr_file]";
        $pr_file->spew(
            q{#!/bin/bash

function die { echo $@; exit 1; }

# logfile=log/deploy.log
# restart=tmp/restart.txt
# umask 002

git diff --quiet || die "Changes to production files found. Aborting."
git ls-files -o  | grep . >/dev/null && die "Untracked files. Aborting."
git checkout -f master
        }
        );
    }
    chmod 0755, $pr_file;

    return;
}

1;

__END__

=pod

=head1 NAME

App::GitDeploy::Command::setup

=head1 VERSION

version 1.09

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
