package HTML::Forms::Field::Date;

use DateTime;
use DateTime::Format::Strptime;
use HTML::Forms::Constants qw( DATE_FMT DATE_MATCH EXCEPTION_CLASS
                               FALSE NUL TRUE );
use HTML::Forms::Types     qw( Bool CodeRef Str );
use HTML::Forms::Util      qw( now );
use Ref::Util              qw( is_coderef );
use Scalar::Util           qw( blessed );
use Try::Tiny;
use Unexpected::Functions  qw( throw );
use Moo;

extends 'HTML::Forms::Field::Text';

has 'clearable' => is => 'ro', isa => Bool, default => FALSE;

has 'date_end' =>
   is      => 'lazy',
   isa     => CodeRef|Str,
   default => NUL,
   clearer => 'clear_date_end';

has 'date_start' =>
   is      => 'lazy',
   isa     => CodeRef|Str,
   default => NUL,
   clearer => 'clear_date_start';

has '+deflate_method' => default => sub { shift->_build_deflate_method };

has 'format' => is => 'lazy', isa => Str, default => DATE_FMT;

has 'format_error' =>
   is      => 'lazy',
   isa     => Str,
   builder => sub {
      my $self = shift;

      return 'Please enter a date in the format ' . $self->format;
   };

has 'locale' => is => 'ro', isa => Str, default => 'en_GB';

has 'pattern' => is => 'ro', isa => Str, default => DATE_MATCH;

has 'time_zone' => is => 'rw', isa => Str, default => 'UTC';

has '+default' => default => sub { shift->_now_dt->truncate( to => 'day' ) };

has '+html5_type_attr' => default => 'date';

has '+size' => default => 10;

has '+type_attr' => default => 'date';

has '+wrapper_class' => default => 'input-date';

before 'get_tag' => sub {
   my $self = shift;

   if ($self->form && $self->form->is_html5
       # subclass may be using different input type
       && $self->html5_type_attr eq 'date'
       && !($self->format =~ m{ \A (yy|%Y)-(mm|%m)-(dd|%d) \z }mx)) {
      warn "Form is HTML5, but date field '" . $self->full_name
         . "' has a format other than %Y-%m-%d, which HTML5 requires for date "
         . "fields. Either correct the input date format or set the is_html5 "
         . "flag to false.";
   }

   return;
};

around 'add_standard_element_classes' => sub {
   my ($orig, $self, $result, $classes) = @_;

   $orig->($self, $result, $classes);

   push @{$classes}, 'clearable' if $self->clearable;

   return;
};

around 'element_attributes' => sub {
   my ($orig, $self, $result) = @_;

   my $attr = $orig->($self, $result);

   $attr->{'max'} = is_coderef $self->date_end
      ? $self->date_end->() : $self->date_end if $self->date_end;

   $attr->{'min'} = is_coderef $self->date_start
      ? $self->date_start->() : $self->date_start if $self->date_start;

   $attr->{'pattern'} = $self->pattern;

   return $attr;
};

after 'init_value' => sub {
   my ($self, $value) = @_;

   $self->time_zone( $value->time_zone->name ) if $value;

   return;
};

our $class_messages = {
   'date_early' => 'Start date is too early',
   'date_late'  => 'End date is too late',
};

# Public methods
sub get_class_messages {
   my $self = shift;

   return { %{ $self->next::method }, %{ $class_messages } };
}

sub validate {
   my $self    = shift;
   my @options = (
      locale    => $self->locale,
      on_error  => 'croak',
      time_zone => $self->time_zone,
   );
   my $format = $self->_get_strf_format;
   my $strp   = DateTime::Format::Strptime->new( pattern => $format, @options );
   my $dt;

   try   { $dt = $strp->parse_datetime($self->value) }
   catch {
      my $error = $strp->errmsg || $_;

      if ($error =~ m{ not \s match }msx) {
         $self->add_error($self->format_error);
      }
      else { $self->add_error($error) }
   };

   return unless $dt;

   $dt->set_time_zone('UTC');
   $self->_set_value($dt);

   my $val_strp = DateTime::Format::Strptime->new(
      pattern => DATE_FMT, time_zone => 'UTC'
   );

   if (my $date_start = $self->date_start) {
      my $date = $dt->clone;

      $date->truncate( to => 'day' ) if $date_start !~ m{ [ ] }mx;
      $date_start = $date_start->() if is_coderef $date_start;
      $date_start = $val_strp->parse_datetime( $date_start );

      throw 'Date start: ' . $val_strp->errmsg unless $date_start;

      my $cmp = DateTime->compare($date_start, $date);

      $self->add_error($self->get_message('date_early')) if $cmp eq 1;
   }

   if (my $date_end = $self->date_end) {
      my $date = $dt->clone;

      $date->truncate( to => 'day' ) if $date_end !~ m{ [ ] }mx;
      $date_end = $date_end->() if is_coderef $date_end;
      $date_end = $val_strp->parse_datetime($date_end);

      throw 'Date end: ' . $val_strp->errmsg unless $date_end;

      my $cmp = DateTime->compare($date_end, $date);

      $self->add_error($self->get_message('date_late')) if $cmp eq -1;
   }

   return;
}

# Private methods
sub _build_deflate_method {
   my $self = shift;

   return sub {
      my ($self, $value) = @_;

      # If not a DateTime, assume correctly formatted string and return
      return $value unless blessed $value && $value->isa('DateTime');

      $value->set_time_zone($self->time_zone);

      return $value->strftime($self->_get_strf_format);
   };
}

# Translator for Datepicker formats to DateTime strftime formats
my $dp_to_dt = {
   'd'  => '\%e',    # day of month (no leading zero)
   'dd' => '\%1',    # day of month (2 digits) "%d"
   'o'  => '\%4',    # day of year (no leading zero) "%{day_of_year}"
   'oo' => '\%j',    # day of year (3 digits)
   'D'  => '\%a',    # day name long
   'DD' => '\%A',    # day name short
   'm'  => '\%5',    # month of year (no leading zero) "%{day_of_month}"
   'mm' => '\%3',    # month of year (two digits) "%m"
   'M'  => '\%b',    # Month name short
   'MM' => '\%B',    # Month name long
   'y'  => '\%2',    # year (2 digits) "%y"
   'yy' => '\%Y',    # year (4 digits)
   '@'  => '\%s',    # epoch
};

sub _get_strf_format {
   my $self   = shift;
   my $format = $self->format;

   # If contains %, then it's a strftime format
   return $format if $format =~ m{ \% }mx;

   for my $dpf (reverse sort keys %{ $dp_to_dt }) {
      my $strf = $dp_to_dt->{$dpf};

      $format =~ s{$dpf}{$strf}gmx;
   }

   $format =~ s/\%1/\%d/g,
   $format =~ s/\%2/\%y/g,
   $format =~ s/\%3/\%m/g,
   $format =~ s/\%4/\%{day_of_year}/g,
   $format =~ s/\%5/\%{day_of_month}/g,

   return $format;
}

sub _now_dt {
   my $self = shift; return now;
}

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Date - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Field::Date;
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

Copyright (c) 2018 Peter Flanigan. All rights reserved

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
