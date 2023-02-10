package Forms::TestMany;

use HTML::Forms::Constants qw( FALSE META TRUE );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Captcha';
with    'HTML::Forms::Role::Defaults';
with    'HTML::Forms::Role::MinimalCSS';
with    'HTML::Forms::Render::Javascript';

has '+title'               => default => 'Test Many Fields';
has '+default_wrapper_tag' => default => 'fieldset';
has '+do_form_wrapper'     => default => TRUE;
has '+do_label_colon'      => default => TRUE;
has '+info_message'        => default => 'You know what to do';

# TODO: Test repeatable field post
# TODO: Fix interval result from post
has_field 'single_boolean' => type => 'Boolean',
   info => 'Each field comes with its own helpful information';

has_field 'boolean_select' => type => 'BoolSelect', auto_widget_size => 2;

has_field 'plain_checkbox' => type => 'Checkbox', checkbox_value => 'foo';

has_field 'multi_checkbox' => type => 'Select', multiple => TRUE,
   auto_widget_size => 3;

has_field 'date_only' => type => 'Date';

has_field 'date_and_time' => type => 'DateTime';

has_field 'duration' => type => 'Duration';
has_field 'duration.hours'   => type => 'Hour', tags => { label_right => TRUE };
has_field 'duration.minutes' => type => 'Minute', tags => { label_right => TRUE };

has_field 'time_period' => type => 'Interval', default => '2 days',
   toggle => {
      hour => [ 'duration' ],
      day  => [ 'date_only' ],
      week => [ 'date_and_time' ],
   };

has_field 'time_with_zone' => type => 'TimeWithZone';

has_field 'year'       => type => 'Year';

has_field 'month'      => type => 'Month';

has_field 'month_name' => type => 'MonthName';

has_field 'weekday'    => type => 'Weekday';

has_field 'day'        => type => 'MonthDay';

has_field 'selector'   => type => 'Group',
   description => 'Grouped selector fields with differing properties';

has_field 'single_select'     => type => 'Select',
   traits => ['+Grouped'], field_group => 'selector';

has_field 'multi_select'      => type => 'Select', multiple => TRUE, size => 4,
   traits => ['+Grouped'], field_group => 'selector';

has_field 'opt_group_select'  => type => 'Select',
   traits => ['+Grouped'], field_group => 'selector';

has_field 'cant_edit_dis'     => type => 'NonEditable',
   value => 'Non editable display text';

has_field 'integer_select'    => type => 'IntRange';

has_field 'positive_integer'  => type => 'PosInteger';

has_field 'floating_number'   => type => 'Float';

has_field 'money'             => type => 'Money';

has_field 'simple_text'       => label => 'Plain Text',
   element_attr => { placeholder => 'Fill me in' };

has_field 'email_address'     => type => 'Email';

has_field 'text_area'         => type => 'TextArea';

has_field 'password'          => type => 'Password', label => 'Cant see dis';

has_field 'password_conf'     => type => 'PasswordConf', label => 'and again',
   password_field => 'password', disabled => TRUE;

has_field 'file_upload'       => type => 'Upload';

has_field 'i_am_robot'        => type => 'Captcha', disabled => TRUE;

has_field 'reorder_by_type'   => type => 'Hidden', default => 'secret';

has_field 'show_me'           => type => 'Display',
   html => '<p>Pick a button, any button</p>';

has_field 'normal_button'     => type => 'Button', value => 'Press Me!';

has_field 'reset_button'      => type => 'Reset', value => 'Restore';

has_field 'submit_button'     => type => 'Submit', value => 'Save';

sub options_single_select {
   return ( 1 => 'One', 2 => 'Two', 3 => 'Three' );
}

sub options_multi_select {
   return ( 1 => 'One', 2 => 'Two', 3 => 'Three', 4 => 'Four', 5 => 'Five' );
}

sub options_opt_group_select {
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
   return ( 1 => 'One', 2 => 'Two', 3 => 'Three' );
}

use namespace::autoclean -except => META;

1;
