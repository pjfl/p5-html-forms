package HTML::Forms::Field::Digits;

use HTML::Forms::Constants qw( META );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::PosInteger';

has '+html5_type_attr' => default => 'text';

has '+widget' => default => 'Digits';

sub javascript {
   my ($self, $count) = @_;

   return qq{oninput="} . $self->js_package . qq{.updateDigits('}
        . $self->id . qq{', } . $count . qq{)"};
}

use namespace::autoclean -except => META;

1;
