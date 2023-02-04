package HTML::Forms::Field::Float;

use HTML::Forms::Constants qw( DOT META NUL TRUE );
use HTML::Forms::Types     qw( Int Str Undef );
use Scalar::Util           qw( weaken );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Text';

has 'decimal_symbol' => is => 'ro', isa => Str, default => DOT;

has 'decimal_symbol_for_db' => is => 'ro', isa => Str, default => DOT;

has 'precision' => is => 'rw', isa => Int|Undef, default => 2;

has '+deflate_method' => default => sub {
   my $self = shift; weaken $self;

   return sub { $self->deflate_float(@_) };
};

has '+inflate_method' => default => sub {
   my $self = shift; weaken $self;

   return sub { $self->inflate_float(@_) };
};

has '+size' => default => 8;

has '+wrapper_class' => default => 'input-number';

our $class_messages = {
   'float_precision' =>
      'May have a maximum of [quant,_1,digit] after the decimal point, but has [_2]',
   'float_needed' =>
      'Must be a number. May contain numbers, +, - and decimal separator \'[_1]\'',
   'float_size' =>
      'Total size of number must be less than or equal to [_1], but is [_2]',
};

sub deflate_float {
   my ($self, $value) = @_;

   return $value unless defined $value;

   my $symbol    = $self->decimal_symbol;
   my $symbol_db = $self->decimal_symbol_for_db;

   $value =~ s{ \Q $symbol_db \E }{$symbol}mx;

   return $value;
}

sub get_class_messages {
   my $self = shift;

   return { %{ $self->next::method }, %{ $class_messages  } };
}

sub inflate_float {
   my ($self, $value) = @_;

   return $value unless defined $value;

   $value =~ s{ \A \+ }{}mx;

   return $value;
}

sub validate {
   my $self = shift;

   my ($integer_part, $decimal_part) = ();
   my $value     = $self->value;
   my $symbol    = $self->decimal_symbol;
   my $symbol_db = $self->decimal_symbol_for_db;

   # \Q ... \E - All the characters between the \Q and the \E are interpreted
   # as literal characters.
   if ($value =~ m{ \A -? ([0-9]+) (\Q$symbol\E([0-9]+))? \z }mx) {
      $integer_part = $1;
      $decimal_part = defined $3 ? $3 : NUL;
   }
   else {
      return $self->add_error( $self->get_message('float_needed'), $symbol );
   }

   if (my $allowed_size = $self->size) {
      my $total_size = length($integer_part) + length($decimal_part);

      return $self->add_error(
         $self->get_message('float_size'), $allowed_size, $total_size
      ) if $total_size > $allowed_size;
   }

   if (my $allowed_precision = $self->precision) {
      return $self->add_error(
         $self->get_message('float_precision'),
         $allowed_precision, length $decimal_part
      ) if length $decimal_part > $allowed_precision;
   }

   # Inflate to database accepted format
   $value =~ s{ \Q $symbol \E }{$symbol_db}mx;
   $self->_set_value($value);

   return TRUE;
}

use namespace::autoclean -except => META;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Float - Generates markup for and processes input from HTML forms

=head1 Synopsis

   use HTML::Forms::Field::Float;
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
