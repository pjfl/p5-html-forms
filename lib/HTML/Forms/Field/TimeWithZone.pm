package HTML::Forms::Field::TimeWithZone;

use DateTime::TimeZone;
use HTML::Forms::Constants qw( DOT META TIME_RE TRUE );
use HTML::Forms::Types     qw( HFsField Maybe Str );
use HTML::Forms::Util      qw( quote_single );
use HTML::Forms::Field::Select;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Hidden';

has '+do_label' => default => TRUE;

has '+widget'   => default => 'TimeWithZone';

has '+wrapper_class' => default => 'input-time-with-zone';

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

has 'update_js_method' =>
   is      => 'lazy',
   isa     => Str,
   default => sub { shift->_js_package . DOT . 'updateTimeWithZone' };

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

has '_js_package' => is => 'ro', isa => Str, default => 'HForms.Util';

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
      my $tmwz    = $self->fif or return 'local';
      my $time_re = TIME_RE;
      my ($zone)  = $tmwz =~ m{ \A $time_re \s (.+) \z }mx;

      return $zone;
   };

before 'before_build' => sub {
   my $self = shift;
   my $form = $self->form;

   if ($form && $form->can('load_js_package')) {
      $form->load_js_package($self->_js_package);
   }

   return;
};

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

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::TimeWithZone - Generates markup for and processes input from HTML forms

=head1 Synopsis

   use HTML::Forms::Field::TimeWithZone;
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

Peter Flanigan, C<< <lazarus@roxsoft.co.uk> >>

=head1 License and Copyright

Copyright (c) 2023 Peter Flanigan. All rights reserved

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
