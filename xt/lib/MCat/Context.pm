package MCat::Context;

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Types     qw( ArrayRef Bool HashRef Str );
use JSON::MaybeXS          qw( encode_json );
use Type::Utils            qw( class_type );
use MCat::Schema;
use Moo;

has 'config', is => 'ro', isa => class_type('MCat::Config'), required => TRUE;

has 'messages' => is => 'lazy', isa => ArrayRef, builder => sub {
   my $self    = shift;
   my $request = $self->request;
   my $session = $request->session;

   return $session->collect_status_messages($request);
};

has 'posted' => is => 'lazy', isa => Bool, builder => sub {
   my $self = shift; return lc $self->request->method eq 'post' ? TRUE : FALSE;
};

has 'request' =>
   is       => 'ro',
   isa      => class_type('Web::ComposableRequest::Base'),
   required => TRUE;

has 'session' => is => 'lazy', builder => sub { shift->request->session };

has 'schema'  => is => 'lazy', isa => class_type('MCat::Schema'),
   builder => sub {
      my $self = shift;

      return MCat::Schema->connect(@{$self->config->connect_info});
   };

has 'stash' => is => 'ro', isa => HashRef, default => sub { {} };

sub model {
   my ($self, $rs_name) = @_; return $self->schema->resultset($rs_name);
}

sub view { TRUE }

use namespace::autoclean;

1;
