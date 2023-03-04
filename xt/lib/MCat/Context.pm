package MCat::Context;

use HTML::Forms::Constants qw( FALSE NUL TRUE );
use HTML::Forms::Types     qw( ArrayRef Bool HashRef Str );
use HTML::Forms::Util      qw( get_token );
use JSON::MaybeXS          qw( encode_json );
use List::Util             qw( pairs );
use MCat::Util             qw( action_path2uri new_uri );
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

has 'models' => is => 'ro', isa => HashRef, weak_ref => TRUE,
   default => sub { {} };

has 'posted' => is => 'lazy', isa => Bool, builder => sub {
   my $self = shift; return lc $self->request->method eq 'post' ? TRUE : FALSE;
};

has 'preference_url' => is => 'lazy', isa => class_type('URI'), builder => sub {
   my $self   = shift;
   my $scheme = $self->request->scheme;

   return new_uri $scheme, $self->request->base . 'api/table/*/preference';
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

has 'table_form_url' => is => 'lazy', isa => class_type('URI'), builder => sub {
   my $self   = shift;
   my $scheme = $self->request->scheme;

   return new_uri $scheme, $self->request->base . 'api/table/*/action';
};

has 'views' => is => 'ro', isa => HashRef, default => sub { {} };

sub model {
   my ($self, $rs_name) = @_; return $self->schema->resultset($rs_name);
}

sub preference {
   my ($self, $name, $value) = @_;

   return unless $name;

   my $rs = $self->model('Preference');

   return $rs->update_or_create(
      { name => $name, value => $value }, { key => 'preference_name' }
   ) if $value && $value ne '""';

   my $pref = $rs->find({ name => $name }, { key => 'preference_name' });

   return $pref unless defined $value;

   return $pref->delete;
}

sub res { shift->response }

sub stash {
   my ($self, @args) = @_;

   return $self->_stash unless $args[0];

   return $self->_stash->{$args[0]} unless $args[1];

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

sub verification_token {
   my $self = shift; return get_token(3600, NUL);
}

sub view {
   my ($self, $view) = @_; return $self->views->{$view};
}

use namespace::autoclean;

1;
