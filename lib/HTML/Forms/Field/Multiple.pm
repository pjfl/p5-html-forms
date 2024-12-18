package HTML::Forms::Field::Multiple;

use HTML::Forms::Constants qw( TRUE );
use Scalar::Util           qw( weaken );
use Moo;

extends 'HTML::Forms::Field::Select';

has '+multiple' => default => TRUE;

has '+size'     => default => 5;

has '+sort_options_method' => default => sub {
   my $self = shift;

   weaken $self;

   return sub { default_sort_options( $self, @_ ) };
};

sub default_sort_options {
   my ($self, $options) = @_;

   return $options unless scalar @{ $options } && defined $self->value;

   my $value = $self->deflate( $self->value );

   return $options unless scalar @{ $value };

   # This places the currently selected options at the top of the list
   # Makes the drop down lists a bit nicer
   my %selected = map { $_ => 1 } @{ $value };
   my @out = grep { $selected{ $_->{value} } } @{ $options };

   push @out, grep { not $selected{ $_->{value} } } @{ $options };

   return \@out;
}

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Multiple - Multiple select

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'Multiple';

=head1 Description

Multiple select

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item has_sort_options_method

Predicate

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item default_sort_options

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::Forms::Field::Select>

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
