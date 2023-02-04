package HTML::Forms::Field::DateTime;

use DateTime;
use HTML::Forms::Constants qw( META TRUE );
use Scalar::Util           qw( blessed );
use Try::Tiny;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Compound';

has '+do_label' => default => TRUE;

has '+do_wrapper' => default => TRUE;

has '+inflate_default_method' => default => sub { \&datetime_inflate };

has '+wrapper_class' => default => 'input-datetime';

our $class_messages = {
   'datetime_invalid' => 'Not a valid DateTime',
};

sub datetime_inflate {
   my ($self, $value) = @_;

   return $value unless blessed $value eq 'DateTime';

   my %hash;

   for my $field ($self->all_fields) {
      my $method = $field->name;

      $hash{$method} = $value->$method;
   }

   return \%hash;
}

sub get_class_messages {
   my $self = shift;

   return { %{ $self->next::method }, %{ $class_messages  } };
}

sub validate {
   my $self = shift;

   my @dt_parms;

   for my $child ($self->all_fields) {
      next unless $child->value;
      push @dt_parms, ($child->accessor => $child->value);
   }

   my $dt;

   try   { $dt = DateTime->new(@dt_parms) }
   catch { $self->add_error( $self->get_message('datetime_invalid') ) };

   if ($dt) { $self->_set_value($dt) }
   else { $self->set_value({ @dt_parms }) }

   return;
}

use namespace::autoclean -except => META;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::DateTime - Generates markup for and processes input from HTML forms

=head1 Synopsis

   use HTML::Forms::Field::DateTime;
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
