package HTML::Forms::Field::Multiple;

use namespace::autoclean;

use Scalar::Util qw( weaken );
use Moo;

extends 'HTML::Forms::Field::Select';

has '+multiple' => default => 1;

has '+size'     => default => 5;

has '+sort_options_method' => default => sub {
   my $self = shift; weaken $self;

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

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Multiple - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Field::Multiple;
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
