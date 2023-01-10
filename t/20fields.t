use t::boilerplate;

use Test::More;

# Boolean
my $class = 'HTML::Forms::Field::Boolean';

use_ok $class;

my $field = $class->new( name => 'test', );

ok defined $field, 'Constructs bool';

$field->build_result;
$field->input( 1 );
$field->validate_field;

ok !$field->has_errors, 'Test for bool errors 1';
is $field->value, 1, 'Test true == 1';

$field->input( 0 );
$field->validate_field;

ok !$field->has_errors, 'Test for bool errors 2';
is $field->value, 0, 'Test true == 0';

$field->input( 'checked' );
$field->validate_field;

ok !$field->has_errors, 'Test for bool errors 3';
is $field->value, 1, 'Test true == 1';

$field->input( '0' );
$field->validate_field;

ok !$field->has_errors, 'Test for bool errors 4';
is $field->value, 0, 'Test true == 0';

is $field->label, 'Test', 'Default bool field label';

# Checkbox
$class = 'HTML::Forms::Field::Checkbox';

use_ok $class;

$field = $class->new( name => 'checkbox_test', required => 1 );

ok defined $field, 'new() checkbox called';

$field->reset_result;
$field->input('checked');
$field->validate_field;

ok !$field->has_errors, 'Test for errors 1';
is $field->value, 'checked', 'Test value == checked';

$field->input(undef);
$field->validate_field;

ok $field->has_errors, 'Test for errors 2';
is $field->errors->[0], 'Checkbox test field is required', 'required error';

# Integer
$class = 'HTML::Forms::Field::Integer';

use_ok $class;

$field = $class->new( name => 'test_field' );

ok defined $field, 'new() integer called';

$field->reset_result;
$field->input( 1 );
$field->validate_field;

ok !$field->has_errors, 'Test for errors 1';
is $field->value, 1, 'Test value == 1';

$field->input( 0 );
$field->validate_field;

ok !$field->has_errors, 'Test for errors 2';
is $field->value, 0, 'Test value == 0';

$field->input( 'checked' );
$field->validate_field;

ok $field->has_errors, 'Test non integer';
is $field->errors->[0], 'Value must be an integer', 'correct error';

$field->input( '+10' );
$field->validate_field;

ok !$field->has_errors, 'Test positive';
is $field->value, 10, 'Test value == 10';

$field->input( '-10' );
$field->validate_field;

ok !$field->has_errors, 'Test negative';
is $field->value, -10, 'Test value == -10';

$field->input( '-10.123' );
$field->validate_field;

ok $field->has_errors, 'Test real number';

$field->range_start( 10 );
$field->input( 9 );
$field->validate_field;

ok $field->has_errors, 'Test 9 < 10 fails';

$field->input( 100 );
$field->validate_field;

ok !$field->has_errors, 'Test 100 > 10 passes ';

$field->range_end( 20 );
$field->input( 100 );
$field->validate_field;

ok $field->has_errors, 'Test 10 <= 100 <= 20 fails';

$field->range_end( 20 );
$field->input( 15 );
$field->validate_field;

ok !$field->has_errors, 'Test 10 <= 15 <= 20 passes';

$field->input( 10 );
$field->validate_field;

ok !$field->has_errors, 'Test 10 <= 10 <= 20 passes';

$field->input( 20 );
$field->validate_field;

ok !$field->has_errors, 'Test 10 <= 20 <= 20 passes';

$field->input( 21 );
$field->validate_field;

ok $field->has_errors, 'Test 10 <= 21 <= 20 fails';

$field->input( 9 );
$field->validate_field;

ok $field->has_errors, 'Test 10 <= 9 <= 20 fails';

# PosInteger
$class = 'HTML::FormHandler::Field::PosInteger';

use_ok $class;

$field = $class->new( name => 'test_field' );

ok defined $field, 'new() posInteger called';

$field->build_result;
$field->input( 1 );
$field->validate_field;

ok !$field->has_errors, 'Test for errors 1';
is $field->value, 1, 'Test value == 1';

$field->input( 0 );
$field->validate_field;

ok !$field->has_errors, 'Test for errors 2';
is $field->value, 0, 'Test value == 0';

$field->input( 'checked' );
$field->validate_field;

ok $field->has_errors, 'Test non integer';

$field->input( '+10' );
$field->validate_field;

ok !$field->has_errors, 'Test positive';
is $field->value, 10, 'Test value == 10';

$field->input( '-10' );
$field->validate_field;

ok $field->has_errors, 'Test negative';
like $field->errors->[ 0 ], qr{ \Qa positive integer\E }mx, 'Valid error';

$field->input( '-10.123' );
$field->validate_field;

ok $field->has_errors, 'Test real number';
like $field->errors->[ 0 ], qr{ \Qan integer\E }mx, 'Valid int error';
like $field->errors->[ 1 ], qr{ \Qa positive integer\E }mx,
   'Valid postint error';

# Multiple
$class = 'HTML::FormHandler::Field::Multiple';

use_ok $class;

$field = $class->new( name => 'test_field' );

ok defined $field, 'new() called';

$field->build_result;
$field->options( [
   { value => 1, label => 'one' },
   { value => 2, label => 'two' },
   { value => 3, label => 'three' },
] );

ok $field->options,  'options method called';

$field->input( 1 );
$field->validate_field;

ok !$field->has_errors, 'Test for errors 1';
is_deeply $field->value, [1], 'Test 1 => [1]';

$field->input( [1] );
$field->validate_field;

ok !$field->has_errors, 'Test for errors 2';
ok eq_array( $field->value, [1], 'test array' ), 'Check [1]';

$field->input( [1,2] );
$field->validate_field;

ok !$field->has_errors, 'Test for errors 3';
ok eq_array( $field->value, [1,2], 'test array' ), 'Check [1,2]';

$field->input( [1,2,4] );
$field->validate_field;

ok $field->has_errors, 'Test for errors 4';
is $field->errors->[0], "'4' is not a valid value", 'Error message';

# Select
$class = 'HTML::FormHandler::Field::Select';

use_ok $class;

$field = $class->new( name => 'test_field' );

ok defined $field,  'new() select called';

$field->build_result;

ok $field->options, 'test for select init_options failure';

my $options = [
   { value => 1, label => 'one' },
   { value => 2, label => 'two' },
   { value => 3, label => 'three' },
];

$field->options($options);

ok $field->options, 'test for select set options failure';

$field->input( 1 );
$field->validate_field;

ok !$field->has_errors, 'test for errors 1';
is $field->value, 1, 'Test true == 1';

$field->input( [1] );
$field->validate_field;

ok $field->has_errors, 'test for errors array';

$field->input( [1,4] );
$field->validate_field;

ok $field->has_errors, 'test for errors 4';
is $field->errors->[0], 'This field does not take multiple values',
   'multi value error message';
is $field->label, 'Test field', 'select field label';

$field = $class->new(
   name         => 'test_prompt',
   empty_select => "Choose a Number",
   options      => $options,
   required     => 1 );

is $field->num_options, 3, 'right number of options';

done_testing;
