package HTML::Forms::Result::Role;

use namespace::autoclean;

use HTML::Forms::Constants qw( EXCEPTION_CLASS TRUE );
use HTML::Forms::Types     qw( ArrayRef HFsFieldResult Str );
use Unexpected::Functions  qw( throw );
use Moo::Role;
use MooX::HandlesVia;

has 'errors'   =>
   is          => 'rw',
   isa         => ArrayRef[Str],
   builder     => sub { [] },
   handles_via => 'Array',
   handles     => {
      _push_errors => 'push',
      all_errors   => 'elements',
      clear_errors => 'clear',
      has_errors   => 'count',
      num_errors   => 'count',
   };

has 'error_results' =>
    is              => 'rw',
    isa             => ArrayRef,
    builder         => sub { [] },
    handles_via     => 'Array',
    handles         => {
        add_error_result    => 'push',
        all_error_results   => 'elements',
        clear_error_results => 'clear',
        has_error_results   => 'count',
        num_error_results   => 'count',
    };

has 'name' => is => 'rw', isa => Str, required => TRUE;

has 'input'  =>
   is        => 'ro',
   clearer   => '_clear_input',
   predicate => 'has_input',
   writer    => '_set_input';

has '_results'  =>
    is          => 'rw',
    isa         => ArrayRef[HFsFieldResult],
    builder     => sub { [] },
    handles_via => 'Array',
    handles     => {
        _pop_result         => 'pop',
        add_result          => 'push',
        clear_results       => 'clear',
        find_result_index   => 'first_index',
        has_results         => 'count',
        num_results         => 'count',
        results             => 'elements',
        set_result_at_index => 'set',
    };

has 'warnings'  =>
    is          => 'rw',
    isa         => ArrayRef[Str],
    builder     => sub { [] },
    handles_via => 'Array',
    handles     => {
        add_warning    => 'push',
        all_warnings   => 'elements',
        clear_warnings => 'clear',
        has_warnings   => 'count',
        num_warnings   => 'count',
    };

sub errors_by_id {
   my $self = shift;
   my %errors;

   for my $error_result ($self->all_error_results) {
      $errors{ $error_result->field_def->id } = [ $error_result->all_errors ];
   }

   return \%errors;
}

sub errors_by_name {
   my $self = shift;
   my %errors;

   for my $error_result ($self->all_error_results) {
      $errors{ $error_result->field_def->html_name }
         = [ $error_result->all_errors ];
   }

   return \%errors;
}

sub field { shift->get_result( @_ ) }

# This ought to be named 'result' for consistency, but the result objects are
# named 'result'. also providing 'field' method for compatibility
sub get_result {
   my ($self, $name, $fatal) = @_;

   # If this is a full_name for a compound field walk through the fields to get
   # to it
   if ($name =~ m{ \. }mx) {
      my @names = split m{ \. }mx, $name; my $result = $self;

      for my $rname (@names) {
         return unless $result = $result->get_result( $rname );
      }

      return $result;
   }
   else { # Not a compound name
      for my $result ($self->results) {
         return $result if $result->name eq $name;
      }
   }

   throw 'Field [_1] not found in [_2]', [ $name, $self ] if $fatal;

   return;
}

sub is_valid { shift->validated }

sub validated { $_[ 0 ]->has_input && !$_[ 0 ]->has_error_results }

1;

