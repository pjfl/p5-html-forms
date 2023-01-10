use t::boilerplate;

use Test::More;

BEGIN {
   eval { require Template }
      or plan skip_all => 'Install Template Toolkit to test Render::WithTT';
}

use_ok 'HTML::Forms';

my $dir = File::ShareDir::dist_dir( 'HTML-Forms' ) . '/templates/';

ok $dir, 'found template dir';

{
   package HTML::Forms::Renderer;

   use Moo::Role;

   with 'HTML::Forms::Render::WithTT';

   sub _build_tt_include_path { [ 'share/templates' ] }
}

my $form = HTML::Forms->new_with_traits(
   name => 'test_tt', traits => [ 'HTML::Forms::Renderer' ],
);

ok $form, 'form builds';
is $form->name, 'test_tt', 'correct form name';
is $form->tt_include_path->[ 0 ], 'share/templates', 'default include path';

$form->add_tt_include_path( 'frodo' );

is $form->tt_include_path->[ 1 ], 'frodo', 'adds extra include paths';

is $form->render,
   "<form id=\"test_tt\" method=\"post\">\n<div class=\"form_messages\">\n  "
 . "</div>\n</form>",
   'renders default form';

my $options = [ { label => 'One', value => 1 },
                { label => 'Two', value => 2 } ];

$form = HTML::Forms->new_with_traits(
   do_form_wrapper     => 1, # Should be called do_form_fieldset
   form_element_class  => 'wicked',
   form_wrapper_class  => [ 'awesome' ],
   form_tags           => { messages_wrapper_class => 'tragic' },
   html_prefix         => 1,
   name                => 'test_tt',
   field_list          => [
      'texty'          => {
         apply         => [ {
            check      => qr/^[0-9a-z]*\z/,
            message    => 'Contains invalid characters' } ],
         element_class => 'magic',
         label_class   => 'gnarly',
         type          => 'Text',
         wrapper_class => 'special',
      },
      'groupy' => {
         description   => 'Two Fields',
         type          => 'Group',
      },
      'selecty'        => {
         field_group   => 'groupy',
         options       => $options,
         multiple      => 1,
         size          => 4,
         toggle        => {
            1          => [ 'foo_section' ],
            2          => [ 'bar_secion' ],
         },
         type          => 'Select',
      },
      'datastructury'  => {
         field_group   => 'groupy',
         reorderable   => 1,
         single_hash   => 1,
         structure     => [
            # Text box with default
            { name  => 'foo', label => 'Field', type => 'text', value => 'na' },
            # Text box without default
            { name  => 'bar', label => 'Clicky', type => 'text' },
            # Checkbox
            { name  => 'rah', label => 'Checkbox', type => 'checkbox' },
            # Radio button group (one per row)
            { name  => 'paf', label => 'Picky', type => 'row_select' },
            # Select box, with options, and default
            { name  => 'gob', label => 'Flicky', type => 'select',
              value => 'raah', options => [
                 { label => 'Raah', value => 'raah' },
                 { label => 'Fooop', value => 'fooop' },
              ]
            },
         ],
         type          => 'DataStructure',
      },
      'datepicky' => {
         clearable => 1,
         type      => 'DatePicker',
      },
      'datetimepicky' => {
         datetime  => 1,
         type      => 'DatePicker',
      },
      'buttony' => {
         default   => 'submit_form',
         html_name => '_method',
         type      => 'Button',
      },
      'intervaly' => {
         default       => '1 hours',
         label_class   => 'tricky',
         type          => 'Interval',
         wrapper_class => 'special',
      },
   ],
   traits              => [ 'HTML::Forms::Renderer' ],
   verbose             => 1,
   widget_form         => 'complex', # Should be called form_trait
);

warn $form->render;

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
