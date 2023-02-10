use t::boilerplate;

use Test::More;

{
   package Test::Defaults;

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'foo' => default => 'default_foo';
   has_field 'bar' => default => q();
   has_field 'bax' => default => 'default_bax';
}

my $form = Test::Defaults->new();
my $cmp_fif = { foo => 'default_foo', bar => q(), bax => 'default_bax', };

# Test that defaults in fields are used in filling in the form
is_deeply $form->fif, $cmp_fif, 'fif has right defaults';

$form->process( params => {} );

is_deeply $form->fif, $cmp_fif, 'fif has right defaults';

my $init_obj = { foo => q(), bar => 'testing', bax => q() };

$form->process( init_object => $init_obj, params => {} );

is_deeply $form->fif, $init_obj, 'object overrides defaults';

{
   package Test::DefaultsX;

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'foo' => default_over_obj => 'default_foo';
   has_field 'bar' => default_over_obj => q();
   has_field 'bax' => default_over_obj => 'default_bax';
}
# test that the 'default_over_obj' type defaults override an init_object/item
$form = Test::DefaultsX->new;
$form->process( init_object => $init_obj, params => {} );

is $form->field( 'foo' )->default_over_obj, 'default_foo', 'foo correct';

is_deeply $form->fif, $cmp_fif, 'fif uses defaults overriding object';

{
   package My::Form;

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has '+name' => default => 'testform_';
   has_field 'optname' => temp => 'First';
   has_field 'reqname' => required => 1;
   has_field 'somename';
}

$form = My::Form->new( init_object => {
   reqname => 'Starting Perl', optname => 'Over Again'
} );
# additional test for init_object provided defaults
ok $form, 'non-db form created OK';
is $form->field( 'optname' )->value, 'Over Again', 'get right value from form';

$form->process( {} );

ok !$form->validated, 'form validated';
is $form->field( 'reqname' )->fif, 'Starting Perl',
   'get right fif with init_object';

{
   package My::Form2;

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has '+name' => default => 'initform_';
   has_field 'foo';
   has_field 'bar';
   has_field 'bax' => default => 'default_bax';
   has '+init_object' => default => sub { { foo => 'initfoo' } };

   sub default_bar { 'init_value_bar' }
}

$form = My::Form2->new;
# test default_<field_name> methods in form
# plus init_object defined in form class
# plus default is used when init_object doesn't have key/accessor
is $form->field( 'foo' )->value, 'initfoo', 'value from init_object';
is $form->field( 'foo' )->fif,   'initfoo', 'fif ok';
is $form->field( 'bar' )->value, 'init_value_bar',
   'value from field default meth';
is $form->field( 'bar' )->fif,   'init_value_bar', 'fif ok';
is $form->field( 'bax' )->value, 'default_bax', 'value from field default';
is $form->field( 'bax' )->fif,   'default_bax', 'fif ok';

{
   package Mock::Object;

   use Moo;

   has 'foo' => is => 'rw';
   has 'bar' => is => 'rw';
   has 'baz' => is => 'rw';
}
{
   package Test::Object;

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';
   with 'HTML::Forms::Model::Object';

   sub BUILD {
      my $self = shift; my $var = 'test';
   }

   has_field 'foo';
   has_field 'bar';
   has_field 'baz';
   has_field 'bax' => default => 'bax_from_default';
   has_field 'zero' => type => 'PosInteger', default => 0;
   has_field 'foo_list' =>
      type    => 'Multiple',
      default => [ 1, 3 ],
      options => [ { value => 1, label => 'One'   },
                   { value => 2, label => 'Two'   },
                   { value => 3, label => 'Three' }, ];

   sub init_object {
      my $self = shift; return { bar => 'initbar' };
   }
}

my $obj = Mock::Object->new( foo => 'myfoo', bar => 'mybar', baz => 'mybaz' );

$form = Test::Object->new;
$form->process( item => $obj, item_id => 1, params => {} );
# test that item is used for value
is $form->field( 'foo' )->value, 'myfoo', 'field value from item';
is $form->field( 'foo' )->fif, 'myfoo', 'field fif from item';
is $form->field( 'bar' )->value, 'mybar', 'field value from item';
is $form->field( 'bar' )->fif, 'mybar', 'field fif from item';
# test that non-item default is used
is $form->field( 'bax' )->value, 'bax_from_default',
   'non-item field value from default';
is $form->field( 'zero' )->value, 0, 'zero default works';
is_deeply $form->field( 'foo_list' )->value, [ 1,3 ], 'multiple default works';

{
   package Test::Object2;

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';
   with 'HTML::Forms::Model::Object';

   has_field 'foo';
   has_field 'bar';
   has_field 'baz';
}

$form = Test::Object2->new;
# test that init_object values are used with 'use_init_obj_over_item' flag
my $def_obj = Mock::Object->new(
   foo => 'def_myfoo', bar => 'def_mybar', baz => 'def_mybaz'
);
my $new_obj = Mock::Object->new;

$form->process(
   item => $new_obj, init_object => $def_obj, use_init_obj_over_item => 1
);

is $form->field( 'foo' )->value, 'def_myfoo', 'value from init_object not item';
is $form->field( 'foo' )->fif, 'def_myfoo', 'fif from init_object not item';

# test that flag is cleared for next run
$form->process( item => $new_obj, init_object => $def_obj );

is $form->field( 'foo' )->value, undef, 'next process without that flag';

{
   package Test::Form;

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has 'quuz' => is => 'ro', default => 'some_quux';
   has_field 'foo';
   has_field 'bar';

   sub init_object {
      my $self = shift; return { foo => $self->quuz, bar => 'bar!' };
   }
}

$form = Test::Form->new;

is $form->field( 'foo' )->value, 'some_quux',
   'field initialized by init_object';

{
   package Mock::Object2;
   use Moo;
   has 'meow' => is => 'rw';
}
{
   package Test::Object3;

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';
   with 'HTML::Forms::Model::Object';

   has_field 'meow' => default => 'this_should_get_overridden';
}

$obj = Mock::Object2->new( meow => 'the_real_meow' );
$form = Test::Object3->new;
$form->process( item => $obj, item_id => 1, params => {} );

is $form->field( 'meow' )->value, 'the_real_meow',
   'defaults should not override actual item values';

{
   package Test::Form2;

   use Moo;
   use HTML::Forms::Moo;
   extends 'HTML::Forms';

   has_field 'foo';
   has_field 'bar';
   has_field 'win';
}

$form = Test::Form2->new;
$form->process( defaults => {
   foo => 'foo_def', bar => 'bar_def', win => 'win_def',
} );

ok !$form->validated, 'no params so not validated';
is $form->field( 'foo' )->default, 'foo_def', 'foo has default';
is $form->field( 'foo' )->fif, 'foo_def', 'fif is correct';
is $form->field( 'bar' )->default, 'bar_def', 'bar has right default';
is $form->field( 'bar' )->fif, 'bar_def', 'bar has correct fif';
is_deeply $form->fif, { foo => 'foo_def', bar => 'bar_def', win => 'win_def' },
   'right fif';

$form->process(
   defaults    => { foo => undef, bar => 'bar_from_defaults' },
   init_object => {
      foo => 'foo_from_obj', bar => 'bar_from_obj', win => 'win_from_obj' },
   use_defaults_over_obj => 1,
);

is $form->field( 'bar' )->fif, 'bar_from_defaults',
   'defaults used instead of init_object';
is $form->field( 'foo' )->fif, 'foo_from_obj',
   'no value from default set to undef';

{
   package Test::Form::Rep;

   use Moo;
   use HTML::Forms::Moo;
   extends 'HTML::Forms';

   with 'HTML::Forms::Render::WithTT';

   has '+name' => default => 'testform';
   has_field 'foo';
   has_field 'myarray' =>
      type         => 'Repeatable',
      do_wrapper   => 1,
      setup_for_js => 1,
      tags         => { controls_div => 1 };
   has_field 'myarray.one';
   has_field 'myarray.two' => type => 'Select';
   has_field 'myarray.three';
   has_field 'myarray.four' => type => 'RmElement';
   has_field 'add_another'  => type => 'AddElement', repeatable => 'myarray';

   sub default_myarray {
      my $self = shift;

      return (
         { one => 'abc1', two => 2, three => 'abc3' },
         { one => 'def1', two => 3, three => 'def3' },
         { one => 'ghi1', two => 1, three => 'ghi3' },
      );
   }

   sub options_myarray_two {
      return ( 1 => 'one', 2 => 'two', 3 => 'three' );
   }

   sub default_myarray_three {
      return 'default_three';
   }
}

$form = Test::Form::Rep->new( verbose => 0 );

ok $form, 'builds repeatable form';

$form->process;

is $form->field('myarray')->num_fields, 3, 'right number of fields';

my $fif     = $form->fif;
my $exp_fif = {
   'foo'             => '',
   'myarray.0.one'   => 'abc1',
   'myarray.0.three' => 'abc3',
   'myarray.0.two'   => 2,
   'myarray.1.one'   => 'def1',
   'myarray.1.three' => 'def3',
   'myarray.1.two'   => 3,
   'myarray.2.one'   => 'ghi1',
   'myarray.2.three' => 'ghi3',
   'myarray.2.two'   => 1,
};

is_deeply( $fif, $exp_fif, 'repeatable fif is correct' );

$fif->{foo} = 'foo_submitted';

$form->process( params => $fif );

my $values     = $form->values;
my $exp_values = {
   foo     => 'foo_submitted',
   myarray => [
      { one => 'abc1', two => 2, three => 'abc3' },
      { one => 'def1', two => 3, three => 'def3' },
      { one => 'ghi1', two => 1, three => 'ghi3' }
   ]
};

is_deeply( $values, $exp_values, 'got expected values' );

{
   package Test::Form::Rep2;

   use Moo;
   use HTML::Forms::Moo;
   extends 'HTML::Forms';

   with 'HTML::Forms::Render::WithTT';

   has_field 'user_name';
   has_field 'occupation';
   has_field 'employers' => type => 'Repeatable', num_extra => 1;
   has_field 'employers.employer_id' => type => 'PrimaryKey';
   has_field 'employers.name';
   has_field 'employers.address';
}

$form = Test::Form::Rep2->new;

my $unemployed_params = {
   user_name  => 'No Employer',
   occupation => 'Unemployed',
   'employers.0.employer_id' => q(),
   'employers.0.name'        => q(),
   'employers.0.address'     => q()
};

$form->process($unemployed_params);

ok $form->validated, 'User with empty employer validates';
is_deeply $form->value, {
   employers => [], user_name => 'No Employer', occupation => 'Unemployed'
}, 'creates right value for empty repeatable';

is_deeply $form->fif, $unemployed_params, 'right fif for empty repeatable';

$form->field('employers')->add_extra;

my $expected_fif = {
   'employers.0.address'     => q(),
   'employers.0.employer_id' => q(),
   'employers.0.name'        => q(),
   'employers.1.address'     => q(),
   'employers.1.employer_id' => q(),
   'employers.1.name'        => q(),
   'occupation' => 'Unemployed',
   'user_name'  => 'No Employer',
};

is_deeply $form->fif, $expected_fif, 'fif is correct with additional element';

done_testing;
