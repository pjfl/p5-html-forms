use t::boilerplate;

use Test::More;

BEGIN {
   eval { require Template }
      or plan skip_all => 'Install Template Toolkit to test Render::WithTT';
}

use_ok 'HTML::Forms';

{
   package HTML::Forms::Renderer;

   use Moo::Role;

   with 'HTML::Forms::Render::WithTT';

   sub _build_tt_include_path { [ 'share/templates' ] }
}

{
   package MyApp::Context;

   use List::Util qw(pairs);
   use Moo;

   has '_session' => is => 'ro', builder => sub { {} };

   sub session {
      my ($self, @args) = @_;

      return $self->_session unless $args[0];

      for my $pair (pairs @args) {
         $self->_session->{$pair->key} = $pair->value;
      }

      return $self->_session;
   }
}

my $ctx = MyApp::Context->new;

ok $ctx, 'builds context';

my $form = HTML::Forms->new_with_traits(
   context     => $ctx,
   html_prefix => 1,
   name        => 'test_tt',
   traits      => [ 'HTML::Forms::Renderer', 'HTML::Forms::Role::Captcha', ],
   widget_form => 'complex', # Should be called form_trait
);

ok $form, 'builds form';

my $field = $form->field('captcha');

ok $field, 'has captcha field';
is $field->captcha_type, 'local', 'local captcha type';
like $form->render, qr{ captcha/image }mx, 'render contains url';

my $params = { test_tt => { captcha => $form->get_captcha->{rnd} } };

$form->process($params);

ok !$field->has_errors, 'field validated';
is $field->value, $form->get_captcha->{rnd}, 'correct value';

$params = { test_tt => { captcha => 12345 } };
$form->process($params);

ok $field->has_errors, 'field has errors';
is $field->errors->[0], 'Verification incorrect. Try again.',
   'incorrect input error';

$field->clear_errors;

ok !$field->has_errors, 'errors cleared';

$params = { test_tt => { foo => 'bar' } };
$form->process($params);

ok $field->has_errors, 'field has errors';
is $field->errors->[0], 'Verification field is required',
   'required field error';

$form = HTML::Forms->new_with_traits(
   ctx         => $ctx,
   html_prefix => 1,
   name        => 'test_tt',
   traits      => [ 'HTML::Forms::Renderer', 'HTML::Forms::Role::Captcha', ],
   widget_form => 'complex', # Should be called form_trait
   field_list  => [
      {
         name         => '+captcha',
         captcha_type => 'remote',
         secret_key   => '6Ld07-0jAAAAANQ2SVbY5ozRGATqho9ct_7v8u1D',
         site_key     => '6Ld07-0jAAAAALpm-PWLePBRrriza0A1yXNbdRKO',
      },
   ],
);

ok $form, 'builds form with field list attr';

$field = $form->field('captcha');

ok $field, 'has captcha field';
is $field->captcha_type, 'remote', 'remote captcha type';
like $form->render, qr{ data-sitekey }mx, 'render contains site key';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
