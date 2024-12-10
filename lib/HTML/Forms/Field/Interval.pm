package HTML::Forms::Field::Interval;

use HTML::Forms::Constants qw( DOT META NUL SPC TRUE );
use HTML::Forms::Types     qw( ArrayRef HashRef HFsField Int Str Undef );
use HTML::Forms::Util      qw( interval_to_string get_meta quote_single );
use HTML::Forms::Field::Integer;
use HTML::Forms::Field::Result;
use HTML::Forms::Field::Select;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Hidden';
with    'HTML::Forms::Widget::Field::Trait::Toggle';

my $DEFAULT_INTERVALS = [
   { value => 'hour', label => 'Hours'  },
   { value => 'day',  label => 'Days'   },
   { value => 'week', label => 'Weeks'  },
   { value => 'mon',  label => 'Months' },
   { value => 'year', label => 'Years'  },
];

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Interval - Numeric intervals

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'Interval';

=head1 Description

Numeric interval field

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item do_label

=cut

has '+do_label' => default => TRUE;

=item widget

=cut

has '+widget'   => default => 'Interval';

=item wrapper_class

=cut

has '+wrapper_class' => default => 'input-interval';

=item interval_options

=cut

has 'interval_options' =>
   is      => 'ro',
   isa     => ArrayRef[HashRef],
   builder => sub { $DEFAULT_INTERVALS };

=item interval_string

=cut

has 'interval_string' =>
   is      => 'lazy',
   isa     => Str,
   builder => sub {
      my $self = shift;
      my $interval = $self->fif || $self->default;
      my $default_period = $self->interval_options->[0]->{value} . 's';

      return interval_to_string($interval, $default_period);
   };

=item period_class

=cut

has 'period_class' =>
   is      => 'ro',
   isa     => Str,
   default => 'input-select';

has '_toggle_copy' =>
   is      => 'lazy',
   isa     => HashRef[ArrayRef],
   default => sub { my $self = shift; return { %{ $self->toggle } } };

=item unit_class

=cut

has 'unit_class' => is => 'ro', isa => Str, default => 'input-text';

=item update_js_method

=cut

has 'update_js_method' =>
   is      => 'lazy',
   isa     => Str,
   default => sub { shift->_js_package . DOT . 'updateInterval' };

has '_js_package' => is => 'ro', isa => Str, default => 'WCom.Form.Toggle';

=item period

=cut

has 'period' =>
   is      => 'lazy',
   isa     => HFsField,
   builder => sub {
      my $self    = shift;
      my $class   = 'HTML::Forms::Field::Select';
      my $options = {
         default       => $self->default_period,
         element_attr  => { javascript => $self->update_js },
         element_class => $self->period_class,
         form          => $self->form,
         options       => $self->interval_options,
         name          => $self->name . '_period',
         toggle        => $self->_toggle_copy,
         traits        => [ '+Toggle' ],
      };
      my $field   = $self->parent->new_field_with_traits($class, $options);
      my $result  = HTML::Forms::Field::Result->new(
         name   => $self->name . '_period',
         parent => $self->result
      );

      $result = $field->_result_from_object( $result, $self->default_period );
      $self->result->add_result( $result );
      return $field;
   };

=item unit

=cut

has 'unit' =>
   is      => 'lazy',
   isa     => HFsField,
   builder => sub {
      my $self    = shift;
      my $class   = 'HTML::Forms::Field::Integer';
      my $options = {
         default       => $self->default_unit,
         element_attr  => { javascript => $self->update_js },
         element_class => $self->unit_class,
         name          => $self->name . '_unit',
         size          => 4,
      };
      my $field   = $self->parent->new_field_with_traits($class, $options);
      my $result  = HTML::Forms::Field::Result->new(
         name   => $self->name . '_unit',
         parent => $self->result
      );

      $result = $field->_result_from_object( $result, $self->default_unit );
      $self->result->add_result( $result );
      return $field;
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

   if ($form && $form->can('load_js_package')) {
      my $method  = $self->update_js_method;
      my $package = $self->_js_package;

      $form->load_js_package($package) if $method =~ m{ \A $package }mx;
   }

   if ($self->has_toggle) {
      $self->_toggle_copy;
      $self->clear_toggle;
   }

   return;
};

=item get_disabled_fields

=cut

around 'get_disabled_fields' => sub {
   my ($orig, $self, $value) = @_;

   $value //= $self->input;

   my ($period) = $value =~ m{ \A \d+ \s* (\w+?) s? \z }mx;

   return $orig->($self, $period);
};

=item default_period

=cut

sub default_period {
   my $self     = shift;
   my $interval = $self->interval_string or return;
   my ($period) = $interval =~ m{ \A \d+ \s* (\w+?) s? \z }mx;

   return $period;
}

=item default_unit

=cut

sub default_unit {
   my $self     = shift;
   my $interval = $self->interval_string or return;
   my ($unit)   = $interval =~ m{ \A (\d+) \s* \w+ \z }mx;

   return $unit;
}

=item update_js

=cut

sub update_js {
   my ($self, $event) = @_;

   $event //= 'onchange';

   return sprintf '%s="%s(%s)"', $event, $self->update_js_method,
      quote_single($self->id);
}

=item validate

=cut

sub validate {
   my $self = shift;
   my $interval = $self->value or return;

   $self->add_error('Not a valid interval value')
      unless $interval =~ m{ \A \d+ \s* \w+ \z }mx;

   return;
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

=item L<HTML::Forms::Widget::Field::Trait::Toggle>

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
