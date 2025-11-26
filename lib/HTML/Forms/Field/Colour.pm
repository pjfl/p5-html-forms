package HTML::Forms::Field::Colour;

use HTML::Forms::Constants qw( FALSE META TRUE );
use HTML::Forms::Types     qw( HFsSelectOptions );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field';

has '+html5_type_attr' => default => 'color';

has '+widget' => default => 'Colour';

has '+wrapper_class' => default => 'input-colour';

=item options

=cut

has 'options'   =>
    is          => 'rw',
    isa         => HFsSelectOptions,
    builder     => 'build_options',
    coerce      => TRUE,
    handles_via => 'Array',
    handles     => {
        all_options   => 'elements',
        clear_options => 'clear',
        has_options   => 'count',
        num_options   => 'count',
        reset_options => 'clear',
    },
    lazy        => TRUE;

use namespace::autoclean -except => META;

1;

