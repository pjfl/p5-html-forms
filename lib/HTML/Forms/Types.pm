package HTML::Forms::Types;

use strictures;

use Type::Library             -base, -declare =>
                          qw( HFs HFsArrayRefStr HFsField HFsFieldResult
                              HFsResult HFsSelectOptions OctalNum Template );
use Type::Utils           qw( as class_type coerce declare extends from
                              inline_as message subtype via where );
use Unexpected::Functions qw( inflate_message );
use Scalar::Util          qw( dualvar isdual );

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

subtype OctalNum, as Str,
   where   { _constraint_for_octalnum($_) },
   message { inflate_message('Value [_1] is not an octal number', $_) };

coerce OctalNum, from Str, via { _coercion_for_octalnum($_) };

sub _coercion_for_octalnum {
   my $x = shift;

   return $x unless length $x;
   return $x if $x =~ m{ [^0-7] }mx;

   $x =~ s{ \A 0 }{}gmx;

   return dualvar oct "${x}", "0${x}";
}

sub _constraint_for_octalnum {
   my $x = shift;

   return 0 unless length $x;
   return 0 if $x =~ m{ [^0-7] }mx;

   $x = dualvar oct "${x}", "0${x}" unless isdual($x);

   return  ($x + 0 < 8) || (oct "${x}" == $x + 0) ? 1 : 0;
}

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

=item L<Type::Library>

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
