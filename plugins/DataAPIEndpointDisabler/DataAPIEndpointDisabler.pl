package MT::Plugin::DataAPIEndpointDisabler;
use strict;
use warnings;
use base qw( MT::Plugin );

my $plugin = __PACKAGE__->new(
    {   name    => 'DataAPIEndpointDisabler',
        version => 0.01,
        description =>
            '<__trans phrase="Disable Data API Endpoints by EnableEndpoints and DisableEndpoints directives.">',
        plugin_link =>
            'https://github.com/masiuchi/mt-plugin-data-api-endpoint-disabler',

        author_name => 'masiuchi',
        author_link => 'https://github.com/masiuchi',

        registry => {
            config_settings => {
                EnableEndpoints  => { default => undef },
                DisableEndpoints => { default => undef },
            },
        },
    }
);
MT->add_plugin($plugin);

{
    require MT::Component;
    my $registry = \&MT::Component::registry;
    require MT::App::DataAPI;
    my $_compile_endpoints = \&MT::App::DataAPI::_compile_endpoints;
    no warnings 'redefine';
    *MT::App::DataAPI::_compile_endpoints = sub {
        my ( $app, $version ) = @_;

        my @enable_endpoints = do {
            my $enable_endpoints = $app->config->EnableEndpoints || '';
            grep {$_} split /\s*,\s*/, $enable_endpoints;
        };

        my @disable_endpoints = do {
            my $disable_endpoints = $app->config->DisableEndpoints || '';
            grep {$_} split /\s*,\s*/, $disable_endpoints;
        };

        local *MT::Component::registry = sub {
            my $reg = $registry->(@_);
            return unless defined $reg;

            if (@enable_endpoints) {
                my @endpoints;
                for my $ep (@$reg) {
                    next unless grep { $_ eq $ep->{id} } @enable_endpoints;
                    push @endpoints, $ep;
                }
                return @endpoints ? \@endpoints : undef;
            }
            elsif (@disable_endpoints) {
                my @endpoints;
                for my $ep (@$reg) {
                    next if grep { $_ eq $ep->{id} } @disable_endpoints;
                    push @endpoints, $ep;
                }
                return @endpoints ? \@endpoints : undef;
            }
            else {
                return $reg;
            }
        };

        return $_compile_endpoints->( $app, $version );
    };
}

1;
