use Module::Build;

my $build = Module::Build->new(
    module_name => 'App::GitDeploy',
    license     => 'perl',
    ## create_readme => 1,
    script_files => [qw(script/git-deploy)],

    configure_requires => {
        'Module::Build' => '0.4004',
    },

    requires => {
        'perl'                => '5.012',
        'App::Cmd'            => 0,
        'IPC::System::Simple' => 0,
        'Path::Class'         => 0,
        'Git::Wrapper'        => 0,
        'Data::Printer'       => 0,
        'autodie'             => 0,
        'URI'                 => 0,
        'File::chdir'         => 0,
        'Net::OpenSSH'        => 0,
        'IO::Pty'             => 0,
        'IO::Stty'            => 0,
        'IO::Prompter'        => 0,
        'Expect'              => 0,
        'Moo'                 => 0,
        'File::ShareDir'      => 0,
        'Term::ReadKey'       => 0,
        'Term::ANSIColor'     => 0,
    },
    build_requires =>
      {    # Should be test_requires, but MB still doesn't handle well
        'Test::Differences' => 0,
        'Test::More'        => 0.87,
      },

    share_dir => 'share',

    meta_merge => {
        resources => {
            bugtracker =>
              'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-GitDeploy',
            repository => 'http://github.com/mvgrimes/app-gitdeploy'
        }
    },
);

$build->create_build_script;

