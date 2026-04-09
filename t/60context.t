use t::boilerplate;

use JSON::MaybeXS;
use URI;
use Test::More;

BEGIN {
   eval { require Template }
      or plan skip_all => 'Install Template Toolkit to test Render::WithTT';
}

use_ok 'HTML::Forms';
{
   package HTML::Forms::Renderer;

   use Moo::Role;

   with 'HTML::Forms::Role::RenderWithTT';

   sub _build_tt_include_path { [ 'share/templates' ] }
}

{
   package MyApp::Context;

   use List::Util qw(pairs);
   use Moo;

   has '_session' => is => 'ro', builder => sub { { id => 1 } };

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

{  package Test::RedisClient;
   use Moo;
   has '_store' => is => 'ro', default => sub { {} };
   has '_ttl'   => is => 'rw';
   sub del {
      my ($self, $key) = @_;
      return delete $self->_store->{$key};
   }
   sub get {
      my ($self, $key) = @_;
      return $self->_store->{$key};
   }
   sub set_with_ttl {
      my ($self, $key, $value, $ttl) = @_;
      $self->_ttl($ttl);
      return $self->_store->{$key} = $value;
   }
}
{  package MyApp::Forms::MyForm;
   use Moo;
   use HTML::Forms::Moo;
   extends 'HTML::Forms';
   has 'json_parser' => is => 'ro', default => sub { JSON::MaybeXS->new };
   has 'redis_client' => is => 'ro', default => sub { Test::RedisClient->new };
   with 'HTML::Forms::Role::Captcha';
   has_field 'captcha' => type => 'Captcha';
}
my $form = MyApp::Forms::MyForm->new_with_traits(
   context     => $ctx,
   html_prefix => 1,
   name        => 'test_tt',
   traits      => [ 'HTML::Forms::Renderer',  ],
   widget_form => 'complex', # Should be called form_trait
   captcha_image_url => URI->new('http://localhost:5000/captcha/image'),
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

$form = MyApp::Forms::MyForm->new_with_traits(
   context     => $ctx,
   html_prefix => 1,
   name        => 'test_tt',
   traits      => [ 'HTML::Forms::Renderer' ],
   widget_form => 'complex', # Should be called form_trait
   captcha_image_url => URI->new('http://localhost:5000/captcha/image'),
);

$params = { test_tt => { captcha => 12345 } };
$form->process($params);

$field = $form->field('captcha');

ok $field->has_errors, 'field has errors';
is $field->errors->[0], 'Verification incorrect. Try again.',
   'incorrect input error';

$field->clear_errors;

ok !$field->has_errors, 'errors cleared';

$params = { test_tt => { foo => 'bar' } };
$form->process($params);

ok $field->has_errors, 'field has errors';
is $field->errors->[0], 'Captcha field is required',
   'required field error';

$form = MyApp::Forms::MyForm->new_with_traits(
   context     => $ctx,
   html_prefix => 1,
   name        => 'test_tt',
   traits      => [ 'HTML::Forms::Renderer' ],
   widget_form => 'complex', # Should be called form_trait
);

ok $form, 'builds form with field list attr';

$field = $form->field('captcha');
$field->captcha_type('remote');

ok $field, 'has captcha field';
is $field->captcha_type, 'remote', 'remote captcha type';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
