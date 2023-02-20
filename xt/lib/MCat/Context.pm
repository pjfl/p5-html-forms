package MCat::Context;

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Types     qw( ArrayRef Bool HashRef Str );
use HTML::Forms::Util      qw( action_path2uri );
use JSON::MaybeXS          qw( encode_json );
use List::Util             qw( pairs );
use Ref::Util              qw( is_arrayref is_hashref );
use Type::Utils            qw( class_type );
use MCat::Response;
use MCat::Schema;
use Moo;

has 'config', is => 'ro', isa => class_type('MCat::Config'), required => TRUE;

has 'messages' => is => 'lazy', isa => ArrayRef, builder => sub {
   my $self = shift;

   return $self->session->collect_status_messages($self->request);
};

has 'posted' => is => 'lazy', isa => Bool, builder => sub {
   my $self = shift; return lc $self->request->method eq 'post' ? TRUE : FALSE;
};

has 'request' =>
   is       => 'ro',
   isa      => class_type('Web::ComposableRequest::Base'),
   required => TRUE;

has 'response' => is => 'ro', isa => class_type('MCat::Response'),
   builder => sub { MCat::Response->new };

has 'session' => is => 'lazy', builder => sub { shift->request->session };

has 'schema'  => is => 'lazy', isa => class_type('MCat::Schema'),
   builder => sub {
      my $self = shift;

      return MCat::Schema->connect(@{$self->config->connect_info});
   };

has '_stash' => is => 'ro', isa => HashRef, default => sub { {} };

sub model {
   my ($self, $rs_name) = @_; return $self->schema->resultset($rs_name);
}

sub res { shift->response }

sub stash {
   my ($self, @args) = @_;

   return $self->_stash unless $args[0];

   for my $pair (pairs @args) {
      $self->_stash->{$pair->key} = $pair->value;
   }

   return $self->_stash;
}

sub uri_for_action {
   my ($self, $action, $args, @params) = @_;

   my $uri    = action_path2uri($action) // $action;
   my $uris   = is_arrayref $uri ? $uri : [ $uri ];
   my $params = is_hashref $params[0] ? $params[0] : {@params};

   for my $candidate (@{$uris}) {
      my $n_stars =()= $candidate =~ m{ \* }gmx;

      next unless $n_stars == 0 or $n_stars <= scalar @{$args // []};

      $uri  = $candidate;
      $uri .= delete $params->{extension} if exists $params->{extension};

      while ($uri =~ m{ \* }mx) {
         my $arg = (shift @{$args // []}) || q(); $uri =~ s{ \* }{$arg}mx;
      }
   }

   return $self->request->uri_for($uri, $args, $params);
}

sub view { TRUE }

use namespace::autoclean;

1;
