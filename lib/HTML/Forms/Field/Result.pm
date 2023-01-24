package HTML::Forms::Field::Result;

use HTML::Forms::Types qw( Bool HFsField );
use Moo;

with 'HTML::Forms::Result::Role';

has 'field_def' =>
    is          => 'ro',
    isa         => HFsField,
    writer      => '_set_field_def';

has 'missing' => is => 'rw', isa => Bool;

has 'value'  =>
   is        => 'ro',
   clearer   => '_clear_value',
   predicate => 'has_value',
   writer    => '_set_value';

sub fif {
   my $self = shift;

   return $self->field_def->fif( $self );
}

sub fields_fif {
   my ($self, $prefix) = @_;

   return $self->field_def->fields_fif( $self, $prefix );
}

sub peek {
   my ($self, $indent) = @_;

   $indent //= q();

   my $name = $self->field_def ? $self->field_def->full_name : $self->name;
   my $type = $self->field_def ? $self->field_def->type : 'unknown';
   my $string = "${indent}result ${name} type: ${type}\n";

   $self->has_value
      and $string .= "${indent}....value => " . $self->value . "\n";

   if ($self->has_results) {
      $indent .= '  ';

      for my $res ($self->results) { $string .= $res->peek( $indent ) }
   }

   return $string;
}

use namespace::autoclean;

1;
