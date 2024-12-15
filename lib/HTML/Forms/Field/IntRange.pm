package HTML::Forms::Field::IntRange;

use HTML::Forms::Constants qw( EXCEPTION_CLASS META );
use HTML::Forms::Types     qw( Str );
use Unexpected::Functions  qw( throw );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Select';

has 'label_format' => is => 'rw', isa => Str, default => '%d';

has '+range_start' => default => 1;

has '+range_end' => default => 10;

has '+wrapper_class' => default => 'input-select-integer';

sub build_options {
   my $self  = shift;
   my $start = $self->range_start;
   my $end   = $self->range_end;
   my $bind  = ['range_start', 'range_end'];

   for ($start, $end) {
      throw 'Both [_1] and [_2] must be defined', $bind unless defined $_;
      throw 'Integer ranges must be integers' unless m{ \A \d+ \z }mx;
   }

   throw '[_1] must be less than [_2]', $bind unless $start < $end;

   my $format = $self->label_format;

   throw 'IntRange needs [_1]', ['label_format'] unless $format;

   return [
      map { { label => $_, value => $_ } }
      map { sprintf $format, $_ } $start .. $end
   ];
}

use namespace::autoclean -except => META;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::IntRange - Integer range

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'IntRange';

=head1 Description

Integer range

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item label_format

=back

=head1 Subroutines/Methods

=over 3

=item build_options

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
