package MCat::Model;

use HTML::Forms::Constants qw( EXCEPTION_CLASS NUL );
use HTML::Forms::Util      qw( verify_token trim );
use HTML::StateTable::Constants qw( RENDERER_PREFIX );
use HTTP::Status           qw( HTTP_OK );
use Scalar::Util           qw( blessed );
use Type::Utils            qw( class_type );
use Unexpected::Functions  qw( exception throw BadToken );
use HTML::Forms::Manager;
use HTML::StateTable::Manager;
use MCat::Context;
use MCat::Schema;
use Moo;

has 'form' =>
   is      => 'lazy',
   isa     => class_type('HTML::Forms::Manager'),
   builder => sub {
      my $self    = shift;
      my $schema  = MCat::Schema->connect(@{$self->config->connect_info});
      my $options = { namespace => 'MCat::Form', schema => $schema };

      return HTML::Forms::Manager->new($options);
   };

has 'table' =>
   is      => 'lazy',
   isa     => class_type('HTML::StateTable::Manager'),
   builder => sub {
      my $self    = shift;
      my $options = { namespace => 'MCat::Table', renderer_class => 'Table' };

      return HTML::StateTable::Manager->new($options);
   };

sub allowed {
   my ($self, $context, $method) = @_; return $method;
}

sub is_token_bad {
   my ($self, $context) = @_;

   my $token = $self->form->get_body_parameters($context)->{_verify};

   return $self->exception_handler($context->request, exception BadToken)
      unless verify_token NUL, $token;

   return;
}

sub error {
   my ($self, $context, $class, @args) = @_;

   my $exception = exception $class, @args;

   return $self->exception_handler($context->request, $exception);
}

sub exception_handler {
   my ($self, $request, $exception) = @_;

   my $message ="${exception}"; chomp $message;

   $self->log->error($message);

   my $code = $exception->code // 0;

   return {
      code      => $code > HTTP_OK ? $code : HTTP_OK,
      exception => $exception,
      message   => $message,
      template  => { layout => 'exception' },
      view      => $self->config->default_view,
   };
}

sub execute {
   my ($self, $method, $request) = @_;

   throw 'Class [_1] has no method [_2]', [ blessed $self, $method ]
      unless $self->can($method);

   my $config  = $self->config;
   my $context = MCat::Context->new( config => $config, request => $request );

   $method = $self->allowed($context, $method);

   my $stash = $self->$method($context, @{$request->args});

   $stash->{code} //= HTTP_OK unless exists $stash->{redirect};
   $stash->{messages} = $context->messages;
   $stash->{template} //= {};
   $stash->{template}->{layout} //= $self->moniker . "/${method}";
   $stash->{view} //= $config->default_view;

   return $stash;
}

use namespace::autoclean;

1;
