package Forms::TestMany;

use HTML::Forms::Constants qw( FALSE META TRUE );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Captcha';
with    'HTML::Forms::Role::Defaults';
with    'HTML::Forms::Render::WithTT';

has '+title'               => default => 'Test Many Fields';
has '+default_wrapper_tag' => default => 'fieldset';
has '+do_form_wrapper'     => default => TRUE;
has '+do_label_colon'      => default => TRUE;
has '+info_message'        => default => 'You know what to do';

# TODO: Add repeatable field
# TODO: Test Toggle - write js first
# TODO: Fix interval result from post
has_field 'single_boolean' => type => 'Boolean',
   info => 'Each field comes with its own helpful information';

has_field 'boolean_select' => type => 'BoolSelect', auto_widget_size => 2;

has_field 'plain_checkbox' => type => 'Checkbox', checkbox_value => 'foo';

has_field 'multi_checkbox' => type => 'Select', multiple => TRUE,
   auto_widget_size => 3;

has_field 'some_date'      => type => 'DateDMY';

has_field 'some_datetime'  => type => 'DateTime';
has_field 'some_datetime.month'  => ( type => 'Month' );
has_field 'some_datetime.day'    => ( type => 'MonthDay' );
has_field 'some_datetime.year'   => ( type => 'Year' );
has_field 'some_datetime.hour'   => ( type => 'Hour' );
has_field 'some_datetime.minute' => ( type => 'Minute' );

has_field 'this_duration'  => type => 'Duration';
has_field 'this_duration.hours'   => ( type => 'Hour' );
has_field 'this_duration.minutes' => ( type => 'Minute' );

has_field 'an_email_address'  => type => 'Email';

has_field 'a_floating_number' => type => 'Float';

has_field 'an_interval'       => type => 'Interval', default => '2 days';

has_field 'select_an_integer' => type => 'IntRange';

has_field 'shylock'           => type => 'Money';

has_field 'month_name'        => type => 'MonthName', label => 'Select Month';

has_field 'cant_edit_dis'     => type => 'NonEditable',
   value => 'Non editable display text';

has_field 'password'          => type => 'Password', label => 'Cant see dis';
has_field 'password_conf'     => type => 'PasswordConf', label => 'and again',
   password_field => 'password', disabled => TRUE;

has_field 'pos_integer'       => type => 'PosInteger',
   label => 'Positive Integer';

has_field 'selector'          => type => 'Group',
   description => 'Grouped selector fields with differing properties';

has_field 'one_of_these'      => type => 'Select',
   traits => ['+Grouped'], field_group => 'selector';

has_field 'select_multi'      => type => 'Select', multiple => TRUE, size => 4,
   traits => ['+Grouped'], field_group => 'selector';

has_field 'select_ogroup'     => type => 'Select',
   traits => ['+Grouped'], field_group => 'selector';

has_field 'simple_text'       => label => 'Text field',
   element_attr => { placeholder => 'Fill me in' };

has_field 'lots_of_text'      => type => 'TextArea';

has_field 'upload_file'       => type => 'Upload';

has_field 'weekday'           => type => 'Weekday';

has_field 'am_robot'          => type => 'Captcha', disabled => TRUE;

has_field 'reorder_by_type'   => type => 'Hidden', default => 'secret';

has_field 'show_me'           => type => 'Display',
   html => '<p>Pick a button, any button</p>';

has_field 'normal_button'     => type => 'Button', value => 'Press Me!';

has_field 'reset_button'      => type => 'Reset', value => 'Restore';

has_field 'submit_button'     => type => 'Submit', value => 'Save';

sub options_one_of_these {
   return ( 1 => 'one', 2 => 'two', 3 => 'three' );
}

sub options_select_multi {
   return ( 1 => 'one', 2 => 'two', 3 => 'three', 4 => 'four', 5 => 'five' );
}

sub options_select_ogroup {
   return (
      {
         group => 'First Group',
         options => [
            { value => 1, label => 'One' },
            { value => 2, label => 'Two' },
            { value => 3, label => 'Three' },
         ],
      },
      {
         group => 'Second Group',
         options => [
            { value => 4, label => 'Four' },
            { value => 5, label => 'Five' },
            { value => 6, label => 'Six' },
         ],
      },
   );
}

sub options_multi_checkbox {
   return ( 1 => 'one', 2 => 'two', 3 => 'three' );
}

use namespace::autoclean -except => META;

1;
