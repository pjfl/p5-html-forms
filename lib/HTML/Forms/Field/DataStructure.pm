package HTML::Forms::Field::DataStructure;

use HTML::Forms::Constants qw( FALSE NUL TRUE );
use HTML::Forms::Types     qw( ArrayRef Bool CodeRef HashRef Str );
use HTML::Forms::Util      qw( encode_only_entities json_bool );
use JSON::MaybeXS          qw( decode_json encode_json );
use Moo;

extends 'HTML::Forms::Field::Text';

has '+html5_type_attr' => default => 'hidden';

has 'drag_title' =>
   is      => 'ro',
   isa     => Str,
   default => 'Drag and drop to reorder rows';

has 'fixed' => is => 'ro', isa => Bool, default => FALSE;

has 'icons' => is => 'rw', isa => Str, default => NUL;

has 'is_row_readonly' =>
   is      => 'ro',
   isa     => CodeRef,
   default => sub { sub { FALSE } };

has 'reorderable' => is => 'ro', isa => Bool, default => FALSE;

has 'row_class' => is => 'ro', isa => Str, default => 'ds-row';

has 'single_hash' => is => 'ro', isa => Bool, default => FALSE;

has 'store_as_hash' => is => 'ro', isa => Bool, default => FALSE;

has 'structure' => is => 'ro', isa => ArrayRef[HashRef], required => TRUE;

has '+type_attr' => default => 'hidden';

has '+widget' => default => 'DataStructure';

sub _build_element_attr {
   my $self     = shift;
   my $readonly = [];

   for my $row (@{decode_json($self->value // '[]')}) {
      push @{$readonly}, json_bool $self->is_row_readonly->($self, $row);
   }

   return {
      'data-ds-specification' => encode_only_entities(encode_json({
         'drag-title'  => $self->drag_title,
         'fixed'       => json_bool $self->fixed,
         'icons'       => $self->icons,
         'is-object'   => json_bool $self->store_as_hash,
         'readonly'    => $readonly,
         'reorderable' => json_bool $self->reorderable,
         'row-class'   => $self->row_class,
         'single-hash' => json_bool $self->single_hash,
         'structure'   => $self->structure,
      }))
   };
}

sub _build_wrapper_class {
   return [ 'compound' ];
}

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::DataStructure - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Field::DataStructure;
   # Brief but working code examples

=head1 Description

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=back

=head1 Subroutines/Methods

=head1 Diagnostics

=head1 Dependencies

=over 3

=item L<Class::Usul>

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

Copyright (c) 2018 Peter Flanigan. All rights reserved

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
