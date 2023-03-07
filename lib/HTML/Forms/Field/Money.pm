use utf8;
package HTML::Forms::Field::Money;

use HTML::Forms::Constants qw( FALSE META );
use HTML::Forms::Types     qw( Bool Int Str );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Text';

has 'allow_commas' => is => 'ro', isa => Bool, default => FALSE;

has 'currency_symbol' => is => 'ro', isa => Str, default => '£';

has 'size' => is => 'ro', isa => Int, default => 8;

has '+html5_type_attr' => default => 'number';

has '+wrapper_class' => default => 'input-money';

our $class_messages = {
   'money_convert' => 'Value cannot be converted to money',
   'money_real'    => 'Must be a real number with only two fractional digits',
};

sub get_class_messages {
   my $self = shift;

   return { %{ $self->next::method }, %{ $class_messages  } };
}

apply([
   {
      transform => sub {
         my ($value, $field) = @_;
         my $symbol = $field->currency_symbol;

         $value =~ s{^\Q$symbol\E}{}mx if $symbol;
         return $value;
      }
   },
   {
      check => sub {
         my ($value, $field) = @_;

         return $field->allow_commas
            ? $value =~ m{ \A [-+]? (?:\d+|\d{1,3}(,\d{3})*) (?:\.\d{2})? \z }mx
            : $value =~ m{ \A [-+]? \d+ (?:\.\d{2})? \z }mx;
      },
      message => sub {
         my ($value, $field) = @_;

         return [ $field->get_message('money_real'), $value ];
      }
   },
   {
      transform => sub {
         my ($value, $field) = @_;

         $value =~ tr/,//d if $field->allow_commas;
         return $value;
      }
   },
   {
      transform => sub { sprintf '%.2f', $_[0] },
      message   => sub {
         my ($value, $field) = @_;

         return [ $field->get_message('money_convert'), $value ];
      }
   }
]);

use namespace::autoclean -except => META;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Money - Generates markup for and processes input from HTML forms

=head1 Synopsis

   use HTML::Forms::Field::Money;
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

Peter Flanigan, C<< <lazarus@roxsoft.co.uk> >>

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
