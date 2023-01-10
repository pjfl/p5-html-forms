package HTML::Forms::Field::DatePicker;

use namespace::autoclean;

use HTML::Entities         qw( encode_entities );
use HTML::Forms::Constants qw( FALSE NUL );
use HTML::Forms::Types     qw( Bool );
use Moo;

extends 'HTML::Forms::Field::Date';

has 'clearable' => is => 'ro', isa => Bool, default => FALSE;

has 'datetime' => is => 'ro', isa => Bool, default => FALSE;

has '+default' => builder => sub {
   my $self = shift;
   my $now  = $self->_now_dt;

   return $self->datetime ? $now : $now->truncate( to => 'day' );
};

has '+format' => default => sub {
   return '%Y-%m-%d' . (shift->datetime ? 'T%H:%M:%S' : NUL);
};

has '+size' => default => sub { shift->datetime ? 19 : 10 };

# Private methods
sub _build_element_attr {
   my $self = shift;

   return { 'data-dp-format' => encode_entities( $self->format ) };
}

sub _build_element_class {
   my $self = shift;
   my $classes = [ $self->datetime ? 'pick-datetime' : 'pick-date' ];

   unshift @{ $classes }, 'clearable' if $self->clearable;

   return $classes;
}

sub _now_dt {
   my $self = shift; my $args = {};

   $args->{locale} = $self->locale if $self->locale;
   $args->{time_zone} = $self->time_zone if $self->time_zone;

   return DateTime->now( %{ $args } );
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::DatePicker - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Field::DatePicker;
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
