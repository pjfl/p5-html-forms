package HTML::Forms::Field::TimeWithZone;

use HTML::Forms::Constants qw( DOT META NUL TIME_RE TRUE );
use HTML::Forms::Types     qw( HFsField Maybe Str );
use HTML::Forms::Util      qw( quote_single );
use HTML::Forms::Field::Result;
use HTML::Forms::Field::Hour;
use HTML::Forms::Field::Minute;
use HTML::Forms::Field::Select;
use DateTime::TimeZone;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Hidden';

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::TimeWithZone - Time with time zone

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'TimeWithZone';

=head1 Description

Time with time zone

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item do_label

=cut

has '+do_label' => default => TRUE;

=item widget

=cut

has '+widget'   => default => 'TimeWithZone';

=item wrapper_class

=cut

has '+wrapper_class' => default => 'input-time-with-zone';

=item hours

=cut

has 'hours' =>
   is      => 'lazy',
   isa     => HFsField,
   builder => sub {
      my $self    = shift;
      my $class   = 'HTML::Forms::Field::Hour';
      my $options = {
         default       => $self->_hours,
         element_attr  => { javascript => $self->_update_js },
         element_class => 'input-select',
         form          => $self->form,
         name          => $self->name . '_hours',
      };
      my $field   = $self->parent->new_field_with_traits($class, $options);
      my $result  = HTML::Forms::Field::Result->new(
         name   => $self->name . '_hours',
         parent => $self->result
      );

      $result = $field->_result_from_object( $result, $self->_hours );
      $self->result->add_result( $result );
      return $field;
   };

=item C<mins>

=cut

has 'mins' =>
   is      => 'lazy',
   isa     => HFsField,
   builder => sub {
      my $self    = shift;
      my $class   = 'HTML::Forms::Field::Minute';
      my $options = {
         default       => $self->_mins,
         element_attr  => { javascript => $self->_update_js },
         element_class => 'input-select',
         form          => $self->form,
         name          => $self->name . '_mins',
      };
      my $field   = $self->parent->new_field_with_traits($class, $options);
      my $result  = HTML::Forms::Field::Result->new(
         name   => $self->name . '_mins',
         parent => $self->result
      );

      $result = $field->_result_from_object( $result, $self->_mins );
      $self->result->add_result( $result );
      return $field;
   };

=item update_js_method

=cut

has 'update_js_method' =>
   is      => 'lazy',
   isa     => Str,
   default => sub { shift->js_package . DOT . 'updateTimeWithZone' };

=item zone

=cut

has 'zone' =>
   is      => 'lazy',
   isa     => HFsField,
   builder => sub {
      my $self    = shift;
      my $class   = 'HTML::Forms::Field::Select';
      my $options = {
         default       => $self->_zone,
         element_attr  => { javascript => $self->_update_js },
         element_class => 'input-select',
         form          => $self->form,
         name          => $self->name . '_zone',
         options       => $self->_zone_options,
      };
      my $field   = $self->parent->new_field_with_traits($class, $options);
      my $result  = HTML::Forms::Field::Result->new(
         name   => $self->name . '_zone',
         parent => $self->result
      );

      $result = $field->_result_from_object( $result, $self->_zone );
      $self->result->add_result( $result );
      return $field;
   };

has '_hours' =>
   is      => 'lazy',
   isa     => Maybe[Str],
   default => sub { (split ':', shift->_time)[0] };

has '_mins' =>
   is      => 'lazy',
   isa     => Maybe[Str],
   default => sub { (split ':', shift->_time)[1] };

has '_time' =>
   is      => 'lazy',
   isa     => Maybe[Str],
   default => sub {
      my $self    = shift;
      my $tmwz    = $self->fif or return '00:00';
      my $time_re = TIME_RE;
      my ($time)  = $tmwz =~ m{ \A ($time_re) \s }mx;

      return $time;
   };

has '_zone' =>
   is      => 'lazy',
   isa     => Maybe[Str],
   default => sub {
      my $self    = shift;
      my $tmwz    = $self->fif or return NUL;
      my $time_re = TIME_RE;
      my ($zone)  = $tmwz =~ m{ \A $time_re \s (.+) \z }mx;

      return $zone;
   };

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILD

=cut

around 'BUILD' => sub {
   my ($orig, $self) = @_;

   $orig->($self);

   my $form = $self->form;

   $form->load_js_package($self->js_package)
      if $form && $form->can('load_js_package');

   return;
};

# Private methods
sub _update_js {
   my ($self, $event) = @_;

   $event //= 'onchange';

   return sprintf '%s="%s(%s)"', $event, $self->update_js_method,
      quote_single($self->id);
}

sub _zone_options {
   return [
      map { +{ label => $_, value => $_ } } DateTime::TimeZone->all_names
   ];
}

use namespace::autoclean -except => META;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::Forms::Field::Hidden>

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
