package HTML::Forms::Result::Role;

use HTML::Forms::Constants qw( EXCEPTION_CLASS TRUE );
use HTML::Forms::Types     qw( ArrayRef HFsFieldResult Str );
use Unexpected::Functions  qw( throw );
use Moo::Role;
use MooX::HandlesVia;

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Result::Role - Results

=head1 Synopsis

   use Moo;

   with 'HTML::Forms::Result::Role';

=head1 Description

Results

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item errors

=cut

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

=item error_results

=cut

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

=item name

=cut

has 'name' => is => 'rw', isa => Str, required => TRUE;

=item input

=item has_input

Predicate

=cut

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

=item warnings

=cut

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

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item errors_by_id

=cut

sub errors_by_id {
   my $self = shift;
   my %errors;

   for my $error_result ($self->all_error_results) {
      $errors{ $error_result->field_def->id } = [ $error_result->all_errors ];
   }

   return \%errors;
}

=item errors_by_name

=cut

sub errors_by_name {
   my $self = shift;
   my %errors;

   for my $error_result ($self->all_error_results) {
      $errors{ $error_result->field_def->html_name }
         = [ $error_result->all_errors ];
   }

   return \%errors;
}

=item field

=cut

sub field { shift->get_result(@_) }

=item get_result

This ought to be named 'result' for consistency, but the result objects are
named 'result'. also providing 'field' method for compatibility

=cut

sub get_result {
   my ($self, $name, $fatal) = @_;

   # If this is a full_name for a compound field walk through the fields to get
   # to it
   if ($name =~ m{ \. }mx) {
      my @names  = split m{ \. }mx, $name;
      my $result = $self;

      for my $rname (@names) {
         return unless $result = $result->get_result($rname);
      }

      return $result;
   }
   else { # Not a compound name
      for my $result ($self->results) {
         return $result if $result->name eq $name;
      }
   }

   throw 'Field [_1] not found in [_2]', [$name, $self] if $fatal;

   return;
}

=item is_valid

=cut

sub is_valid { shift->validated }

=item validated

Have added the test for C<has_errors>. This was not present in
L<HTML::FormHandler>

=cut

sub validated {
   my $self = shift;

   $self->has_input && !$self->has_errors && !$self->has_error_results;
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo::Role>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Forms.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2024 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
