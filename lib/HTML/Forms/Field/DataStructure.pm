package HTML::Forms::Field::DataStructure;

use HTML::Forms::Constants qw( FALSE NUL TRUE );
use HTML::Forms::Types     qw( ArrayRef Bool HashRef Str );
use HTML::Forms::Util      qw( encode_only_entities );
use JSON::MaybeXS          qw( encode_json );
use Moo;

extends 'HTML::Forms::Field::Text';

has '+html5_type_attr' => default => 'hidden';

has 'reorderable' => is => 'ro', isa => Bool, default => FALSE;

has 'single_hash' => is => 'ro', isa => Bool, default => FALSE;

has 'structure' => is => 'ro', isa => ArrayRef[HashRef], required => TRUE;

has '+type_attr' => default => 'hidden';

has '+widget' => default => 'DataStructure';

sub _build_element_attr {
   my $self = shift;
   my $spec = encode_json( $self->structure );

   return {
      'data-ds-spec'        => encode_only_entities( $spec ),
      'data-ds-reorderable' => $self->reorderable,
      'data-ds-single-hash' => $self->single_hash,
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
