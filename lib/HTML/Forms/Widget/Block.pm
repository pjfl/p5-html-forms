package HTML::Forms::Widget::Block;

use namespace::autoclean;

use HTML::Forms::Constants qw( NUL TRUE );
use HTML::Forms::Types     qw( ArrayRef Bool CodeRef HashRef
                               HFs HFsArrayRefStr Str );
use HTML::Forms::Util      qw( process_attrs );
use Scalar::Util           qw( weaken );
use Moo;
use MooX::HandlesVia;

with 'HTML::Forms::Render::WithTT';

has 'after_plist' => is => 'rw', isa => Str, default => NUL;

has 'attr' =>
   is          => 'rw',
   isa         => HashRef,
   builder     => sub { {} },
   handles_via => 'Hash',
   handles     => {
      delete__attr => 'delete',
      has_attr     => 'count',
      set__attr    => 'set',
   };

has 'build_render_list_method' =>
   is          => 'rw',
   isa         => CodeRef,
   builder     => sub { default_build_render_list->( shift ) },
   handles_via => 'Code',
   handles     => { build_render_list => 'execute_method', },
   lazy        => TRUE;

has 'class'    =>
   is          => 'rw',
   isa         => HFsArrayRefStr,
   builder     => sub { [] },
   handles_via => 'Array',
   handles     => {
      add_class => 'push',
      has_class => 'count',
   };

has 'content' => is => 'rw', isa => Str, default => NUL;

has 'form' => is => 'ro', isa => HFs, required => TRUE, weak_ref => TRUE;

has 'label' => is => 'rw', isa => Str, predicate => 'has_label';

has 'label_class' =>
   is          => 'rw',
   isa         => HFsArrayRefStr,
   builder     => sub { [] },
   handles_via => 'Array',
   handles     => {
      add_label_class => 'push',
      has_label_class => 'count',
   };

has 'label_tag' => is => 'rw', isa => Str, default => 'span';

has 'name' => is => 'ro', isa => Str, required => TRUE;

has 'render_list' =>
   is          => 'rw',
   isa         => ArrayRef[Str],
   builder     => 'build_render_list',
   handles_via => 'Array',
   handles     => {
      add_to_render_list => 'push',
      all_render_list    => 'elements',
      get_render_list    => 'get',
      has_render_list    => 'count',
   },
   lazy        => TRUE;

has 'tag' => is => 'rw', isa => Str, default => 'div';

has 'wrapper' => is => 'rw', isa => Bool, default => TRUE;

# Public methods
sub block_label_attributes {
   my ($self, $result) = @_;

   $result //= $self->result;

   my $attr  = { %{ $self->label_attr } };
   my $class = [ @{ $self->label_class } ];

   $self->add_standard_label_classes( $result, $class );

   $attr->{class} = $class if scalar @{ $class };

   return $attr;
}

sub block_wrapper_attributes {
   my ($self, $result) = @_;

   $result //= $self->result;

   my $attr  = { %{ $self->attr } };
   my $class = [ @{ $self->class } ];

   $self->add_standard_wrapper_classes( $result, $class );

   $attr->{class} = $class if scalar @{ $class };

   return $attr;
}

sub default_build_render_list {
   my $self = shift;

   return sub { [] };
}

# Private methods
sub _build_default_tt_vars {
   my $self = shift; weaken $self;
   my $form = $self->form; weaken $form;

   return {
      blockw        => $self,
      form          => $form,
      get_tag       => sub { $form->get_tag( @_ ) },
      localise      => sub { $form->localise( @_ ) },
      process_attrs => \&process_attrs,
   };
}

sub _build_tt_template {
   return 'classic/block.tt';
}

1;

__END__
