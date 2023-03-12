package HTML::Forms::Types;

use strictures;

use Type::Library             -base, -declare =>
                          qw( HFs HFsArrayRefStr HFsField HFsFieldResult
                              HFsResult HFsSelectOptions Template );
use Type::Utils           qw( as class_type coerce declare extends from
                              inline_as message via where );
use Unexpected::Functions qw( inflate_message );

BEGIN { extends 'Unexpected::Types' };

class_type HFs, { class => 'HTML::Forms' };

class_type HFsField, { class => 'HTML::Forms::Field' };

class_type HFsFieldResult, { class => 'HTML::Forms::Field::Result' };

class_type HFsResult, { class => 'HTML::Forms::Result' };

class_type Template, { class => 'Template' };

declare HFsArrayRefStr => as ArrayRef;

coerce HFsArrayRefStr, from Str, via { return length $_ ? [ $_ ] : [] };

coerce HFsArrayRefStr, from Undef, via { return [] };

declare HFsSelectOptions => as ArrayRef[HashRef];

coerce HFsSelectOptions, from ArrayRef[Str] => via {
   my @options = @{ $_ }; my $opts;

   @options % 2 and die 'Options array must contain an even number of elements';

   while (@options) {
      push @{ $opts }, { value => shift @options, label => shift @options };
   }

   return $opts;
};

coerce HFsSelectOptions, from ArrayRef[ArrayRef] => via {
   my @options = @{ $_[ 0 ][ 0 ] }; my $opts;

   push @{ $opts }, { value => $_, label => $_ } for @options;

   return $opts;
};

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Types - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Types;
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

Copyright (c) 2023 Peter Flanigan. All rights reserved

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
