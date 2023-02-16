package MCat::Model;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use HTML::Forms::Util      qw( verify_token );
use HTTP::Status           qw( HTTP_OK );
use Scalar::Util           qw( blessed );
use Type::Utils            qw( class_type );
use Unexpected::Functions  qw( exception throw BadToken NoMethod );
use HTML::Forms::Manager;
use HTML::StateTable::Manager;
use MCat::Context;
use MCat::Schema;
use Moo;

has 'form' =>
   is      => 'lazy',
   isa     => class_type('HTML::Forms::Manager'),
   builder => sub {
      my $self     = shift;
      my $appclass = $self->config->appclass;
      my $schema   = MCat::Schema->connect(@{$self->config->connect_info});
      my $options  = { namespace => "${appclass}::Form", schema => $schema };

      return HTML::Forms::Manager->new($options);
   };

has 'table' =>
   is      => 'lazy',
   isa     => class_type('HTML::StateTable::Manager'),
   builder => sub {
      my $self     = shift;
      my $appclass = $self->config->appclass;
      my $options  = {
         namespace      => "${appclass}::Table",
         renderer_class => 'Table',
      };

      return HTML::StateTable::Manager->new($options);
   };

sub allowed { # Allows all. Apply a role to modify this for permissions
   my ($self, $context, $method) = @_; return $method;
}

sub error { # Stash exception handler output to print an exception page
   my ($self, $context, $class, @args) = @_;

   $self->exception_handler($context, exception $class, level => 2, @args);
   return;
}

sub exception_handler { # Also called by component loader if model dies
   my ($self, $context, $exception) = @_;

   my $message ="${exception}"; chomp $message;

   $self->log->error($message);

   my $code = $exception->rv // 0;

   $context->stash(
      code      => $code > HTTP_OK ? $code : HTTP_OK,
      exception => $exception,
      message   => $message,
      template  => { layout => 'exception' },
      view      => $self->config->default_view,
   );
   return;
}

sub execute { # Called by component loader for all model methods
   my ($self, $context, $method) = @_;

   throw NoMethod, [ blessed $self, $method ] unless $self->can($method);

   $method = $self->allowed($context, $method);

   $self->$method($context, @{$context->request->args});

   my $stash = $context->stash;

   $stash->{code} //= HTTP_OK unless exists $stash->{redirect};
   $stash->{messages} = $context->messages;
   $stash->{template} //= {};
   $stash->{template}->{layout} //= $self->moniker . "/${method}";
   $stash->{view} //= $self->config->default_view;
   return;
}

sub get_context {
   my ($self, $request) = @_;

   return MCat::Context->new( config => $self->config, request => $request );
}

sub has_valid_token { # Stash an exception if the CSRF token is bad
   my ($self, $context) = @_;

   my $token = $self->form->get_body_parameters($context)->{_verify};

   return TRUE if verify_token NUL, $token;

   $self->error($context, BadToken, level => 3);
   return FALSE;
}

use namespace::autoclean;

1;
