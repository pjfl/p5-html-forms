package HTML::Forms::Field::Interval;

use English                qw( -no_match_vars );
use HTML::Forms::Constants qw( DOT META NUL SPC TRUE );
use HTML::Forms::Types     qw( ArrayRef HashRef HFsField Int Str Undef );
use HTML::Forms::Util      qw( interval_to_string get_meta quote_single );
use HTML::Forms::Field::Result;
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

my $JAVASCRIPT = do { local $RS = undef; <DATA> };

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

has 'javascript' => is => 'ro', isa => Str, default => $JAVASCRIPT;

has 'period_class' =>
   is      => 'ro',
   isa     => Str,
   default => 'input input--select';

has '_toggle_copy' =>
   is      => 'lazy',
   isa     => HashRef[ArrayRef],
   default => sub { my $self = shift; return { %{ $self->toggle } } };

has 'unit_class' =>
   is      => 'ro',
   isa     => Str,
   default => 'input input--text input--autosize';

has 'update_js_method' =>
   is      => 'lazy',
   isa     => Str,
   default => sub { shift->_js_package . DOT . 'updateInterval' };

has '_js_package' => is => 'ro', isa => Str, default => 'HForms.Util';

has '+do_label' => default => TRUE;

has '+widget'   => default => 'Interval';

has '+wrapper_class' => default => 'input-interval';

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
         options       => $self->interval_options,
         name          => $self->name . '-period',
         toggle        => $self->_toggle_copy,
         traits        => [ '+Toggle' ],
      };
      my $field   = $self->parent->new_field_with_traits($class, $options);
      my $result  = HTML::Forms::Field::Result->new(
         name   => $self->name . '-period',
         parent => $self->result
      );

      $result = $field->_result_from_object( $result, $self->default_period );
      $self->result->add_result( $result );
      return $field;
   };

has 'unit' =>
   is      => 'lazy',
   isa     => HFsField,
   builder => sub {
      my $self    = shift;
      my $class   = 'HTML::Forms::Field::Integer';
      my $options = {
         default       => $self->default_unit,
         element_attr  => {
            javascript => $self->update_js,
            size       => 4,
         },
         element_class => $self->unit_class,
         name          => $self->name . '-unit',
      };
      my $field   = $self->parent->new_field_with_traits($class, $options);
      my $result  = HTML::Forms::Field::Result->new(
         name   => $self->name . '-unit',
         parent => $self->result
      );

      $result = $field->_result_from_object( $result, $self->default_unit );
      $self->result->add_result( $result );
      return $field;
   };

before 'before_build' => sub {
   my $self = shift;

   if ($self->has_toggle) {
      $self->_toggle_copy;
      $self->clear_toggle;
   }

   return;
};

after 'after_build' => sub {
   my $self = shift;
   my $form = $self->form or return;

   return unless $form->render_js_after;

   my $after   = $form->get_tag('after');
   my $method  = $self->update_js_method;
   my $package = $self->_js_package;

   return unless $method =~ m{ \A $package }mx;
   return if     $after  =~ m{ $package \s+ = }mx;

   $form->set_tag( after => $after . $self->javascript );
   return;
};

around 'get_disabled_fields' => sub {
   my ($orig, $self, $value) = @_;

   $value //= $self->input;

   my ($period) = $value =~ m{ \A \d+ \s* (\w+?) s? \z }mx;

   return $orig->($self, $period);
};

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
   my ($self, $event) = @_;

   $event //= 'onchange';

   return sprintf '%s="%s(%s)"', $event, $self->update_js_method,
      quote_single($self->id);
}

sub validate {
   my $self = shift;
   my $interval = $self->value or return;

   $self->add_error('Not a valid interval value')
      unless $interval =~ m{ \A \d+ \s* \w+ \z }mx;

   return;
}

use namespace::autoclean -except => META;

1;

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

__DATA__
<script>
   if (!window.HForms) window.HForms = {};
   if (!HForms.Util) HForms.Util = {};
   HForms.Util = (function () {
      const onReady = function(callback) {
         if (document.readyState != 'loading') callback();
         else if (document.addEventListener)
            document.addEventListener('DOMContentLoaded', callback);
         else document.attachEvent('onreadystatechange', function() {
            if (document.readyState == 'complete') callback();
         });
      };
      const updateInterval = function(field) {
         const hidden = document.getElementById(field);
         const period = document.getElementById(field + '-period');
         hidden.value = document.getElementById(field + '-unit').value
                      + ' ' + period.value;
         if (period.dataset.toggleConfig) HForms.Toggle.toggleFields(period);
      };

      return {
         onReady: onReady,
         updateInterval: updateInterval
      };
   })();
</script>
