package HTML::Forms::Field::Interval;

use HTML::Forms::Constants qw( META SPC TRUE );
use HTML::Forms::Types     qw( ArrayRef Int Str Undef );
use HTML::Forms::Util      qw( interval_to_string get_meta quote_single );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Hidden';
with    'HTML::Forms::Fields';
with    'HTML::Forms::InitResult';
with    'HTML::Forms::Widget::Field::Trait::Toggle';

my $DEFAULT_INTERVALS = [
   { value => 'hour', label => 'Hours'  },
   { value => 'day',  label => 'Days'   },
   { value => 'week', label => 'Weeks'  },
   { value => 'mon',  label => 'Months' },
   { value => 'year', label => 'Years'  },
];

has 'interval_options' =>
   is      => 'ro',
   isa     => ArrayRef,
   builder => sub { $DEFAULT_INTERVALS };

has 'interval_string' =>
   is      => 'lazy',
   isa     => Str,
   builder => sub {
      my $self = shift;
      my $interval = $self->fif || $self->default;
      my $default_period = $self->interval_options->[0]->{value} . 's';

      return interval_to_string($interval, $default_period);
   };

has 'period_class' =>
   is      => 'ro',
   isa     => Str,
   default => 'input input--select';

has 'unit_class' =>
   is      => 'ro',
   isa     => Str,
   default => 'input input--text input--autosize';

has 'update_js_method' =>
   is      => 'ro',
   isa     => Str,
   default => 'Util.updateInterval';

has '+do_label' => default => TRUE;

has '+widget'   => default => 'Interval';

sub BUILD {
   my $self = shift;
   my $meta = get_meta($self);

   $self->_toggle_event('onchange');
   $meta->add_to_field_list({
      name          => 'period',
      default       => $self->default_period,
      element_attr  => {
         javascript => $self->update_js('period'),
         $self->toggle_config_key => $self->toggle_config_encoded,
      },
      element_class => $self->toggle_class . SPC . $self->period_class,
      options       => $self->interval_options,
      type          => 'Select'
   });
   $meta->add_to_field_list({
      name          => 'unit',
      default       => $self->default_unit,
      element_attr  => { javascript => $self->update_js('unit'), size => 4, },
      element_class => $self->unit_class,
      type          => 'Integer'
   });
   $self->build_fields;

   return;
}

sub default_period {
   my $self     = shift;
   my $interval = $self->interval_string or return;
   my ($period) = $interval =~ m{ \A \d+ \s* (\w+?) s? \z }mx;

   return $period;
}

sub default_unit {
   my $self     = shift;
   my $interval = $self->interval_string or return;
   my ($unit)   = $interval =~ m{ \A (\d+) \s* \w+ \z }mx;

   return $unit;
}

sub update_js {
   my ($self, $field_name, $event) = @_;

   $event //= 'onchange';

   return sprintf '%s="%s(%s, %s)"', $event, $self->update_js_method,
      quote_single($self->id), quote_single($field_name);
}

around 'get_disabled_fields' => sub {
   my ($orig, $self, $value) = @_;

   $value //= $self->input;

   my ($period) = $value =~ m{ \A \d+ \s* (\w+?) s? \z }mx;

   return $orig->($self, $period);
};

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

=pod

=encoding utf-8

=head1 Name

[% module %] - [% abstract %]

=head1 Synopsis

has_field 'interval_field' => (
   type    => '+HTML::Forms::Field::Interval',
   toggle  => { hour => ['display_field'] },
   default => '1 hours',
);

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
http://rt.cpan.org/NoAuth/Bugs.html?Dist=[% distname %].
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

[% author %], C<< <[% author_email %]> >>

=head1 License and Copyright

Copyright (c) [% copyright_year %] [% copyright %]. All rights reserved

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
