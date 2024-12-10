package HTML::Forms::Field::Result;

use HTML::Forms::Types qw( Bool HFsField );
use Moo;

with 'HTML::Forms::Result::Role';

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Result - Result class for fields

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'Result';

=head1 Description

Result class for L<HTML::Forms::Field>. Applies L<HTML::Forms::Result::Role>

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item field_def

=cut

has 'field_def' =>
    is          => 'ro',
    isa         => HFsField,
    writer      => '_set_field_def';

=item missing

=cut

has 'missing' => is => 'rw', isa => Bool;

=item value

=item has_value

Predicate

=cut

has 'value'  =>
   is        => 'ro',
   clearer   => '_clear_value',
   predicate => 'has_value',
   writer    => '_set_value';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item C<fif>

=cut

sub fif {
   my $self = shift;

   return $self->field_def->fif( $self );
}

=item fields_fif

=cut

sub fields_fif {
   my ($self, $prefix) = @_;

   return $self->field_def->fields_fif( $self, $prefix );
}

=item peek

=cut

sub peek {
   my ($self, $indent) = @_;

   $indent //= q();

   my $name = $self->field_def ? $self->field_def->full_name : $self->name;
   my $type = $self->field_def ? $self->field_def->type : 'unknown';
   my $string = "${indent}result ${name} type: ${type}\n";

   $string .= "${indent}....value => " . $self->value . "\n"
      if $self->has_value;

   if ($self->has_results) {
      $indent .= '  ';

      for my $res ($self->results) { $string .= $res->peek( $indent ) }
   }

   return $string;
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::Forms::Result::Role>

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
