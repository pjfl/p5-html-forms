package HTML::Forms::Field::Compound;

use HTML::Forms::Constants qw( FALSE META TRUE );
use HTML::Forms::Types     qw( ArrayRef Bool );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field';
with    'HTML::Forms::Fields';
with    'HTML::Forms::InitResult';

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Compound - Field that contains fields

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'Compound';

=head1 Description

Field that contains fields

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item is_compound

=cut

has 'is_compound' => is => 'ro', isa => Bool, default => TRUE;

=item item

=cut

has 'item' => is => 'rw', clearer => 'clear_item';

=item primary_key

=item has_primary_key

Predicate

=cut

has 'primary_key' =>
   is             => 'rw',
   isa            => ArrayRef,
   predicate      => 'has_primary_key';

=item do_label

=cut

has '+do_label'   => default => FALSE;

=item do_wrapper

=cut

has '+do_wrapper' => default => FALSE;

=item field_name_space

=cut

has '+field_name_space' =>
   builder => sub {
      my $self = shift;

      return $self->form && $self->form->field_name_space
           ? $self->form->field_name_space : [];
   };

=item widget

=cut

has '+widget' => default => 'Compound';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILD

=cut

sub BUILD {
   my $self = shift;

   $self->build_fields;
   return;
}

=item test_validate_field

This is for testing compound fields outside of a form

=cut

sub test_validate_field {
   my $self = shift;

   unless ($self->form) {
      if ($self->has_input) {
         $self->_result_from_input( $self->result, $self->input );
      }
      else { $self->_result_from_fields( $self->result ) }
   }

   $self->validate_field;

   unless ($self->form) {
      for my $err_res (@{ $self->result->error_results }) {
         $self->result->_push_errors( $err_res->all_errors );
      }
   }

   return;
}

=item clear_data

=cut

after 'clear_data' => sub {
   my $self = shift;

   $self->clear_item;
   return;
};

around '_result_from_input' => sub {
   my ($orig, $self, $self_result, $input, $exists) = @_;

   return $self->_result_from_fields( $self_result ) if !$input && !$exists;

   return $orig->( $self, $self_result, $input, $exists );
};

around '_result_from_object' => sub {
   my ($orig, $self, $self_result, $item) = @_;

   $self->item( $item ) if $item;

   return $orig->( $self, $self_result, $item );
};

use namespace::autoclean -except => META;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::Forms::Field'>

=item L<HTML::Forms::Fields>

=item L<HTML::Forms::InitResult>

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
