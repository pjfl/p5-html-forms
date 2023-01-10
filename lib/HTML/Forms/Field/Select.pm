package HTML::Forms::Field::Select;

use namespace::autoclean -except => '_html_forms_meta';

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Types     qw( Bool CodeRef HFsSelectOptions Int Undef );
use Moo;
use HTML::Forms::Moo;
use MooX::HandlesVia;

extends 'HTML::Forms::Field';

has 'multiple' => is => 'rw', isa => Bool, default => FALSE;

has 'options'   =>
    is          => 'rw',
    isa         => HFsSelectOptions,
    builder     => 'build_options',
    coerce      => TRUE,
    handles_via => 'Array',
    handles     => {
        all_options   => 'elements',
        clear_options => 'clear',
        has_options   => 'count',
        num_options   => 'count',
        reset_options => 'clear',
    },
    lazy        => TRUE;

has 'size' => is => 'rw', isa => Int|Undef;

has 'sort_options_method' =>
   is          => 'rw',
   isa         => CodeRef,
   handles_via => 'Code',
   handles     => {
      sort_options => 'execute',
   },
   predicate   => 'has_sort_options_method';

has '+widget' => default => 'Select';

sub build_options { [] }

sub html_element {
   return 'select';
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Select - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Field::Select;
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
