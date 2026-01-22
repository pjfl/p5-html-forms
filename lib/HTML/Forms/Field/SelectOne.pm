package HTML::Forms::Field::SelectOne;

use HTML::Forms::Constants qw( FALSE META NUL TRUE );
use HTML::Forms::Types     qw( Str );
use JSON::MaybeXS          qw( encode_json );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Text';

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::SelectOne - Selects one item from many items in a list

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'SelectOne';

=head1 Description

Selects one item from many items in a list

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item callback

=cut

has 'callback' => is => 'rw', isa => Str;

=item click_handler

=cut

has 'click_handler' =>
   is       =>  'lazy',
   isa      => Str,
   init_arg => undef,
   default  => sub {
      my $self     = shift;
      my $selector = $self->selector;

      return "${selector}";
   };

=item display_as

=cut

has 'display_as' => is => 'lazy', isa => Str, default => sub { shift->label };

=item icons

=cut

has 'icons' => is => 'rw', isa => Str;

=item modal

=cut

has 'modal' => is => 'rw', isa => Str;

=item selector

=cut

has 'selector' =>
   is      => 'rw',
   isa     => Str,
   lazy    => TRUE,
   default => sub {
      my $self   = shift;
      my $modal  = $self->modal;
      my $params = {
         callback => $self->callback,
         icons    => $self->icons,
         target   => $self->name,
         title    => $self->title,
      };

      if ($self->selector_url) { $params->{url} = $self->selector_url }
      else { $params->{items} = encode_json($self->options) }

      my $args = encode_json($params);

      return "${modal}.createSelector(${args})";
   };

=item selector_url

=cut

has 'selector_url' => is => 'rw', isa => Str;

=item widget

=cut

has '+widget' => default => 'SelectOne';

=item wrapper_class

=cut

has '+wrapper_class' => default => 'input-selector';

=back

=head1 Subroutines/Methods

Defines no methods

=over 3

=cut

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
