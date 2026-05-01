package HTML::Forms::Field::Permission;

use HTML::Forms::Util qw( int2rwx );
use JSON::MaybeXS     qw( encode_json );
use Moo;

extends 'HTML::Forms::Field::SelectMany';

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Permission - Permission field

=head1 Synopsis

   use HTML::Forms::Field::Permission;

=head1 Description

Permission field

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=cut

has '+callback' =>
   default => sub {
      my $self   = shift;
      my $params = { lookup => {}, target => $self->name, value => '%value' };

      for my $option (@{$self->options}) {
         $params->{lookup}->{$option->{value}} = $option->{label};
      }

      my $util = $self->form_util;
      my $args = encode_json($params);

      return "${util}.updatePermission(${args})",
   };

=item selector

=cut

has '+selector' =>
   default => sub {
      my $self   = shift;
      my $modal  = $self->modal;
      my $params = {
         callback => $self->callback,
         icons    => $self->icons,
         target   => '_' . $self->name,
         title    => $self->title,
      };

      if ($self->selector_url) { $params->{url} = $self->selector_url }
      else { $params->{items} = encode_json($self->options) }

      my $args = encode_json($params);

      return "${modal}.createSelector(${args})";
   };

has '+widget' => default => 'Permission';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=cut

sub build_options {
   return [
      { label => 'Owner Read',    value => 256 },
      { label => 'Owner Write',   value => 128 },
      { label => 'Owner Execute', value =>  64 },
      { label => 'Group Read',    value =>  32 },
      { label => 'Group Write',   value =>  16 },
      { label => 'Group Execute', value =>   8 },
      { label => 'Other Read',    value =>   4 },
      { label => 'Other Write',   value =>   2 },
      { label => 'Other Execute', value =>   1 },
   ];
}

sub fif {
   my $self = shift; return int2rwx $self->value;
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo>

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

Copyright (c) 2026 Peter Flanigan. All rights reserved

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
