package MCat::API::Table;

use HTML::Forms::Constants qw( DOT NUL TRUE );
use HTML::Forms::Types     qw( Object Str );
use JSON::MaybeXS          qw( encode_json );
use Moo;

has 'form' => is => 'ro', isa => Object, required => TRUE;

has 'name' => is => 'ro', isa => Str, required => TRUE;

sub action {
   my ($self, $context, @args) = @_;

   my $response;

   if ($context->posted) {
      my $params = $self->form->get_body_parameters($context);
      my ($moniker, $method) = split m{ / }mx, $params->{data}->{action};

      $context->models->{$moniker}->execute($context, $method);
   }

   return;
}

sub preference {
   my ($self, $context, @args) = @_;

   my $name = $self->_preference_name;
   my $pref;

   if ($context->posted) {
      my $value = $self->form->get_body_parameters($context)->{data};

      $pref = $context->preference($name, $value);
   }
   else { $pref = $context->preference($name) }

   $context->stash( body => encode_json($pref ? $pref->value : {}));
   return;
}

sub _preference_name {
   return 'table' . DOT . shift->name . DOT . 'preference';
}

use namespace::autoclean;

1;
