package MCat::Model;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use HTML::Forms::Types     qw( Object );
use HTTP::Status           qw( HTTP_OK );
use Scalar::Util           qw( blessed );
use Unexpected::Functions  qw( throw );
use HTML::Forms::Manager;
use MCat::Context;
use MCat::Schema;
use Moo;

has 'form' =>
   is      => 'lazy',
   isa     => Object,
   builder => sub {
      my $self    = shift;
      my $schema  = MCat::Schema->connect(@{$self->config->connect_info});
      my $options = { namespace => 'MCat::Form', schema => $schema };

      return HTML::Forms::Manager->new($options);
   };

sub exception_handler { ... }

sub execute {
   my ($self, $method, $req) = @_;

   throw 'Class [_1] has no method [_2]', [ blessed $self, $method ]
      unless $self->can( $method );

   my $config  = $self->config;
   my $context = MCat::Context->new( config => $config, request => $req );
   my $stash   = $self->$method( $context );

   $stash->{code} //= HTTP_OK;
   $stash->{messages} = $context->messages;
   $stash->{template} //= {};
   $stash->{template}->{layout} //= $self->moniker. '/'. $method;
   $stash->{view} //= $config->default_view;

   return $stash;
}

use namespace::autoclean;

1;
