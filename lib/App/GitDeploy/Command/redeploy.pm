package App::GitDeploy::Command::redeploy;

# ABSTRACT: ...

use 5.012;
use strict;
use warnings;
use Path::Class;
use Data::Printer;
use Path::Class qw(dir file);
use File::chdir;
use App::GitDeploy::SSH;
use App::GitDeploy::Config;
use Role::Tiny::With;

use App::GitDeploy -command;
with 'App::GitDeploy::Role::Run';

our $VERSION = '1.09';

sub opt_spec {
    return (
        # [ "app|a=s",    "The app to deploy", { default => '.' } ],
        # [ "remote|r=s", "The remote repos",  { default => 'production' } ],
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    my $config       = $self->app->validate_global_opts();
    my $app          = $self->app->global_options->{app};
    my $remote       = $self->app->global_options->{remote};
    my $post_receive = "deploy/$app/$remote/post-receive";

    $self->usage_error("A valid app must be specificed")
      unless -d "deploy/$app/";
    $self->usage_error("$post_receive must be created")
      unless -e $post_receive;
    $self->usage_error("$post_receive must be executable")
      unless -x $post_receive;

    return 1;
}

sub execute {
    my ( $self, $opt, $arg ) = @_;
    my $app    = $self->app->global_options->{app};
    my $remote = $self->app->global_options->{remote};

    # run( { cmd => "deploy/$app/$remote/before-deploy", if_exists => 1 } );
    # run( { cmd => "git push --tags $remote master" } );
    # run( { cmd => "deploy/$app/$remote/after-deploy",  if_exists => 1 } );

    my $post_receive =
      file("deploy/$app/$remote/post-receive")->cleanup->stringify;

    $self->run( {
        cmd  => qq{eval "\$( git show master:$post_receive )"},
        host => $self->app->config->remote_url,
    } );

    $self->run( {
        cmd       => "deploy/$app/$remote/before-restart",
        host      => $self->app->config->deploy_url,
        if_exists => 1
    } );
    $self->run( {
        cmd       => "deploy/$app/$remote/restart",
        host      => $self->app->config->deploy_url,
        if_exists => 1
    } );
    $self->run( {
        cmd       => "deploy/$app/$remote/after-restart",
        host      => $self->app->config->deploy_url,
        if_exists => 1
    } );
}

1;

__END__

=pod

=head1 NAME

App::GitDeploy::Command::redeploy - ...

=head1 VERSION

version 1.09

=head1 DESCRIPTION

See L<App::EditorTools> for documentation.

=head1 NAME

App::EditorTools::Command::RenamePackageFromPath - Rename the Package Based on the Path of the File

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
