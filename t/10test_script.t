use t::boilerplate;

use Test::More;

use_ok 'HTML::Forms';

my $form = HTML::Forms->new(
   name => 'user_form',
   field_list => [
      'username' => {
         type  => 'Text',
         apply => [ {
            check   => qr/^[0-9a-z]*\z/,
            message => 'Contains invalid characters' } ],
      },
      'select_bar' => {
         type     => 'Select',
         options  => [],
         multiple => 1,
         size     => 4,
      },
   ],
);

is $form->name, 'user_form', 'Form name';
is $form->index->{select_bar}->order, 2, 'Field order';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
