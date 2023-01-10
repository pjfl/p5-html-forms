package HTML::Forms::Field::PrimaryKey;

use namespace::autoclean;

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Types     qw( Bool );
use Moo;

extends 'HTML::Forms::Field';

has '+do_label' => default => FALSE;

has 'is_primary_key' => is => 'ro', isa => Bool, default => TRUE;

has '+no_value_if_empty' => default => TRUE;

has '+widget' => default => 'Hidden';

sub BUILD {
   my $self = shift;

   if ($self->has_parent) {
      if ($self->parent->has_primary_key) {
         push @{ $self->parent->primary_key }, $self;
      }
      else { $self->parent->primary_key( [ $self ] ) }
   }

   return;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::PrimaryKey - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Field::PrimaryKey;
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
