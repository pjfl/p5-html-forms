package HTML::Forms::Field::Digits;

use HTML::Forms::Constants qw( META );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::PosInteger';

has '+html5_type_attr' => default => 'text';

has '+widget' => default => 'Digits';

use namespace::autoclean -except => META;

1;
