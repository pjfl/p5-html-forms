package HTML::Forms::Field::DataStructure;

use HTML::Forms::Constants qw( FALSE NUL TRUE );
use HTML::Forms::Types     qw( ArrayRef Bool CodeRef HashRef Str );
use HTML::Forms::Util      qw( encode_only_entities json_bool );
use JSON::MaybeXS          qw( decode_json encode_json );
use Moo;

extends 'HTML::Forms::Field::Text';

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::DataStructure - Add and remove groups of fields

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'DataStructure';

=head1 Description

Add and remove groups of fields. Like L<HTML::Forms::Field::Repeatable> but
better

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item add_handler

=cut

has 'add_handler' => is => 'rw', isa => Str, default => NUL;

=item add_icon

=cut

has 'add_icon' => is => 'ro', isa => Str, default => 'add';

=item add_title

=cut

has 'add_title' => is => 'ro', isa => Str, default => 'Add';

=item html5_type_attr

=cut

has '+html5_type_attr' => default => 'hidden';

=item drag_title

=cut

has 'drag_title' =>
   is      => 'ro',
   isa     => Str,
   default => 'Drag and drop to reorder rows';

=item field_group_direction

=cut

has 'field_group_direction' => is => 'ro', isa => Str, default => 'horizontal';

=item fixed

=cut

has 'fixed' => is => 'ro', isa => Bool, default => FALSE;

=item icons

=cut

has 'icons' => is => 'rw', isa => Str, default => NUL;

=item is_row_readonly

=cut

has 'is_row_readonly' =>
   is      => 'ro',
   isa     => CodeRef,
   default => sub { sub { FALSE } };

=item remove_callback

=cut

has 'remove_callback' => is => 'ro', isa => Str, default => NUL;

=item reorderable

=cut

has 'reorderable' => is => 'ro', isa => Bool, default => FALSE;

=item single_hash

=cut

has 'single_hash' => is => 'ro', isa => Bool, default => FALSE;

=item store_as_hash

=cut

has 'store_as_hash' => is => 'ro', isa => Bool, default => FALSE;

=item structure

=cut

has 'structure' => is => 'ro', isa => ArrayRef[HashRef], required => TRUE;

=item type_attr

=cut

has '+type_attr' => default => 'hidden';

=item widget

=cut

has '+widget' => default => 'DataStructure';

=back

=head1 Subroutines/Methods

Defines no methods

=cut

sub _build_element_attr {
   my $self     = shift;
   my $readonly = [];

   for my $row (@{decode_json($self->value // '[]')}) {
      push @{$readonly}, json_bool $self->is_row_readonly->($self, $row);
   }

   return {
      'data-ds-specification' => encode_only_entities(encode_json({
         'add-handler'      => $self->add_handler,
         'add-icon'         => $self->add_icon,
         'add-title'        => $self->add_title,
         'drag-title'       => $self->drag_title,
         'field-group-dirn' => $self->field_group_direction,
         'fixed'            => json_bool $self->fixed,
         'icons'            => $self->icons,
         'is-object'        => json_bool $self->store_as_hash,
         'readonly'         => $readonly,
         'remove-callback'  => $self->remove_callback,
         'reorderable'      => json_bool $self->reorderable,
         'single-hash'      => json_bool $self->single_hash,
         'structure'        => $self->structure,
      }))
   };
}

sub _build_wrapper_class {
   return [ 'compound' ];
}

use namespace::autoclean;

1;

__END__

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::Forms::Field::Text>

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
