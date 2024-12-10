package HTML::Forms::Field::Money;

use utf8;

use HTML::Forms::Constants qw( FALSE META );
use HTML::Forms::Types     qw( Bool Int Str );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Text';

our $class_messages = {
   'money_convert' => 'Value cannot be converted to money',
   'money_real'    => 'Must be a real number with only two fractional digits',
};

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Money - Money field

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'Money';

=head1 Description

Money field

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item allow_commas

=cut

has 'allow_commas' => is => 'ro', isa => Bool, default => FALSE;

=item currency_symbol

=cut

has 'currency_symbol' => is => 'ro', isa => Str, default => '£';

=item size

=cut

has 'size' => is => 'ro', isa => Int, default => 8;

=item html5_type_attr

=cut

has '+html5_type_attr' => default => 'number';

=item wrapper_class

=cut

has '+wrapper_class' => default => 'input-money';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item get_class_messages

=cut

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

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::Forms::Field::Text>

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
