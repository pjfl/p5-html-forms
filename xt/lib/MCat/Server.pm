package MCat::Server;

use HTML::Forms::Constants qw( TRUE );
use HTML::Forms::Types     qw( HashRef Object Str );
use HTTP::Status           qw( HTTP_FOUND );
use MCat::Config;
use MCat::Log;
use Plack::Builder;
use Web::Simple;

has '_config_attr' =>
   is       => 'ro',
   isa      => HashRef,
   init_arg => 'config',
   builder  => sub { { name => 'Music Catalog' } };

has 'config' =>
   is      => 'lazy',
   isa     => Object,
   builder => sub { MCat::Config->new(shift->_config_attr) };

has 'log' => is => 'lazy', isa => Object, builder => sub { MCat::Log->new };

with 'Web::Components::Loader';

around 'to_psgi_app' => sub {
   my ($orig, $self, @args) = @_;

   my $psgi_app = $orig->($self, @args);
   my $conf     = $self->config;
   my $static   = $conf->static;

   return builder {
      enable 'ConditionalGET';
      enable 'Options', allowed => [ qw( DELETE GET POST PUT HEAD ) ];
      enable 'Head';
      enable 'ContentLength';
      enable 'FixMissingBodyInRedirect';
      enable 'Deflater',
         content_type => $conf->deflate_types, vary_user_agent => TRUE;
      enable 'Static',
         path => qr{ \A / (?: $static ) }mx, root => $conf->root;
      mount $conf->mount_point => builder {
         enable 'Session::Cookie',
            expires     => 7_776_000,
            httponly    => TRUE,
            path        => $conf->mount_point,
            samesite    => 'None',
            secret      => $conf->secret,
            secure      => TRUE,
            session_key => $conf->prefix.'_session';
         $psgi_app;
      };
      mount '/' => builder {
         sub { [ HTTP_FOUND, [ 'Location', $conf->default_route ], [] ] }
      };
   };
};

use namespace::autoclean;

1;
