package HTML::Forms::Field::Checkbox;

use HTML::Forms::Constants qw( META );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field';

has 'checkbox_value'       => is => 'rw', default => 1;

has '+html5_type_attr'     => default => 'checkbox';

has '+input_without_param' => default => 0;

has 'option_label'         => is => 'rw';

has 'option_wrapper'       => is => 'rw';

has '+type_attr'           => default => 'checkbox';

has '+widget'              => default => 'Checkbox';

has '+wrapper_class'       => default => 'input-checkbox';

around 'after_build' => sub {
   my ($orig, $self) = @_;

   $self->add_label_class('label-checkbox');
   return;
};

sub validate {
    my $self = shift;

    $self->add_error($self->get_message('required'), $self->loc_label)
       if $self->required && !$self->value;

    return;
}

use namespace::autoclean -except => META;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Checkbox - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Field::Checkbox;
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

Copyright (c) 2017 Peter Flanigan. All rights reserved

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
