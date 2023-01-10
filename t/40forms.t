use t::boilerplate;

use Test::More;

{
   package MyApp::Form::Field::MyComp;

   use HTML::Forms::Types qw( Bool );
   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms::Field::Compound';

   has 'state' => is => 'ro', isa => Bool, default => 0;

   has_field 'foo';
   has_field 'bar';

   sub field_list {
      my $self = shift;

      $self->state and return [ zed => 'Text' ];

      return [];
   }
}
{
   package MyApp::Form::Test;

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has '+field_name_space' => default => 'MyApp::Form::Field';

   has_field 'mimi';
   has_field 'tutu';
   has_field 'foofoo' => type => 'MyComp', state => 1;
}

my $form = MyApp::Form::Test->new;

ok $form, 'Form constructs';
ok $form->field( 'foofoo.zed' ), 'Nested field_list field was created';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
