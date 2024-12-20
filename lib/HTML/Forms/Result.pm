package HTML::Forms::Result;

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Types     qw( ArrayRef Bool HFs Str );
use Moo;
use MooX::HandlesVia;

with 'HTML::Forms::Result::Role';

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Result - Result class

=head1 Synopsis

   use HTML::Forms::Result;

=head1 Description

Result class

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item form

=cut

has 'form'   =>
   is       => 'ro',
   isa      => HFs,
   #  handles => ['render' ],
   weak_ref => TRUE;

=item form_errors

=cut

has 'form_errors' =>
   is          => 'rw',
   isa         => ArrayRef[Str],
   default     => sub { [] },
   handles_via => 'Array',
   handles     => {
      all_form_errors   => 'elements',
      clear_form_errors => 'clear',
      has_form_errors   => 'count',
      num_form_errors   => 'count',
      push_form_errors  => 'push',
   };

=item ran_validation

=cut

has 'ran_validation' => is => 'rw', isa => Bool, default => FALSE;

=item has_value

=cut

has '_value'  =>
    is        => 'ro',
    clearer   => '_clear_value',
    predicate => 'has_value',
    reader    => '_get_value',
    writer    => '_set_value';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item C<fif>

=cut

sub fif {
   my $self = shift;

   return $self->form->fields_fif( $self );
}

=item form_and_field_errors

=cut

sub form_and_field_errors {
    my $self = shift;
    my @field_errors = map { $_->all_errors } $self->all_error_results;
    my @form_errors = $self->all_form_errors;

    return (@form_errors, @field_errors);
}

=item peek

=cut

sub peek {
    my $self = shift;
    my $string = 'Form Result ' . $self->name . "\n";
    my $indent = '  ';

    for my $res ($self->results) { $string .= $res->peek( $indent ) }

    return $string;
}

=item validated

=cut

sub validated {
    my $self = shift;

    return $self->has_input && !$self->has_error_results
       && !$self->has_form_errors ? TRUE : FALSE;
}

=item value

=cut

sub value { shift->_get_value || {} }

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
