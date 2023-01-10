package HTML::Forms::Util;

use strictures;
use parent 'Exporter::Tiny';

use Data::Clone            qw( clone );
use DateTime::Duration;
use HTML::Entities         qw( );
use HTML::Forms::Constants qw( TRUE FALSE NUL SPC );
use Ref::Util              qw( is_arrayref is_blessed_ref is_hashref );

our @EXPORT = qw( cc_widget convert_full_name duration_to_string
                  encode_only_entities has_some_value inflate_interval
                  interval_to_string merge process_attrs quote_single
                  ucc_widget );

my $INTERVAL_REGEXP = {
   hours  => qr{ \A (h|hours?) }imx,
   days   => qr{ \A (d|days?) \z }imx,
   weeks  => qr{ \A (w|weeks?) \z }imx,
   months => qr{ \A (mon(s)?|months?) \z }imx,
   years  => qr{ \A (y|years?) \z }imx,
};

my $MATRIX = {
   SCALAR => {
      SCALAR => sub { $_[ 0 ] },
      ARRAY  => sub { [ $_[ 0 ], @{ $_[ 1 ] } ] },
      HASH   => sub { $_[ 1 ] },
   },
   ARRAY => {
      SCALAR => sub { [ @{ $_[ 0 ] }, $_[ 1 ] ] },
      ARRAY  => sub { [ @{ $_[ 0 ] }, @{ $_[ 1 ] } ] },
      HASH   => sub { $_[ 1 ] },
   },
   HASH => {
      SCALAR => sub { $_[ 0 ] },
      ARRAY  => sub { $_[ 0 ] },
      HASH   => sub { _merge_hashes( $_[ 0 ], $_[ 1 ] ) },
   },
};

my $PERIOD_CONVERSION = {
   seconds => {
      minutes => 60,
      hours   => 3_600,
      days    => 86_400,        #60 * 60 * 24,
      weeks   => 604_800,       #60 * 60 * 24 * 7,
      months  => 2_592_000,     #60 * 60 * 24 * 30,
      years   => 31_536_000,    #60 * 60 * 24 * 365,
   },
   minutes => {
      hours  => 60,
      days   => 1_440,          #60 * 24,
      weeks  => 10_080,         #60 * 24 * 7,
      months => 43_200,         #60 * 24 * 30,
      years  => 525_600,        #60 * 24 * 365,
   },
   hours => {
      days   => 24,
      weeks  => 168,            #24 * 7,
      months => 720,            #24 * 30,
      years  => 8760,           #24 * 365,
   },
   days => {
      weeks  => 7,
      months => 30,
      years  => 365,
   },
   weeks => {
      months => 4,
      years  => 52,
   },
   months => { years => 12, },
   years  => {},
};

# Public functions
sub cc_widget ($) {
   my $widget = shift;

   if ($widget and $widget eq lc $widget) {
      $widget =~ s{ \A (\w{1}) }{\u$1}gmx;
      $widget =~ s{ _(\w{1}) }{\u$1}gmx;
   }

   return $widget;
}

sub convert_full_name ($) {
   my $full_name = shift;

   $full_name =~ s{ \. \d+ \. }{_}gmx;
   $full_name =~ s{ \. }{_}gmx;

   return $full_name;
}

sub duration_to_string ($$) {
   my ($duration, $default_period) = @_;

   $default_period //= 'seconds';

   die 'DateTime::Duration object required'
      unless $duration->isa( 'DateTime::Duration' );

   my @periods = qw( seconds minutes hours days weeks months years );
   my $smallest_period;

   for my $period (@periods) {
      next unless $duration->$period > 0;

      $smallest_period = $period;
      last;
   }

   #If we have no units ('00:00:00'?) use default units in output
   $smallest_period //= $default_period;

   my $time_units = $duration->$smallest_period;
   my $conversion_lookup = $PERIOD_CONVERSION->{ $smallest_period };

   for my $period (keys %{$conversion_lookup}) {
      $time_units += $conversion_lookup->{ $period } * $duration->$period;
   }

   return "${time_units} ${smallest_period}";
}

sub encode_only_entities {
   my $html = shift;

   # Encode control chars and high bit chars, but leave '<', '&', '>', ''' and
   # '"'. Encode as decimal rather than hex, to keep Lotus Notes happy.
   $html =~ s{([^<>&"'\n\r\t !\#\$%\(-;=?-~])}{ #"emacs
      $HTML::Entities::char2entity{$1} || '&#' . ord($1) . ';'
   }ge;

   return $html;
}

sub has_some_value {
   my $x = shift;

   return unless defined $x;
   return $x =~ m{ \S }mx ? TRUE : FALSE unless ref $x;

   if (is_arrayref $x) {
      for my $elem (@{ $x }) { return TRUE if has_some_value( $elem ) }

      return FALSE;
   }

   if (is_hashref $x) {
      for my $key (keys %{ $x }) {
         return TRUE if has_some_value( $x->{ $key } );
      }

      return FALSE;
   }

   return TRUE if is_blessed_ref $x or ref $x;

   return FALSE;
}

sub inflate_interval {
   my $interval = shift;
   my @parts    = $interval =~ m{ (\d+ \s* \w+) }gmx;
   my %duration;

   if ($interval =~ m{ (\d+) : (\d+) : (\d+) }mx) {
      %duration = (hours => $1, minutes => $2, seconds => $3);
   }

   for my $interval (@parts) {
      my ($unit, $period) = $interval =~ m{ (\d+) \s* (\w+) }mx;

      while (my ($valid_period, $regexp) = each %{ $INTERVAL_REGEXP }) {
         $duration{ $valid_period } = $unit if $period =~ $regexp;
      }
   }

   return DateTime::Duration->new( %duration );
}

sub interval_to_string ($$) {
   my ($interval, $default_period) = @_;

   my $duration = inflate_interval( $interval );

   return duration_to_string( $duration, $default_period );
}

sub merge ($$) {
   my ($left, $right) = @_;

   my $lefttype  = is_hashref  $left  ? 'HASH'
                 : is_arrayref $left  ? 'ARRAY' : 'SCALAR';
   my $righttype = is hashref  $right ? 'HASH'
                 : is_arrayref $right ? 'ARRAY' : 'SCALAR';

   $left  = clone( $left );
   $right = clone( $right );

   return $MATRIX->{ $lefttype }{ $righttype }->( $left, $right );
}

# This is a function for processing various attribute flavors
sub process_attrs {
   my $attrs = shift;

   $attrs ||= {};

   my $javascript = delete $attrs->{javascript} // NUL;
   my @use_attrs;

   for my $attr (sort keys %{ $attrs }) {
      my $value = NUL;

      if (defined $attrs->{ $attr }) {
         if (is_arrayref $attrs->{ $attr }) {
            # We don't want class="" if no classes specified
            next unless scalar @{ $attrs->{ $attr } };
            $value = join SPC, @{ $attrs->{ $attr } };
         }
         else { $value = $attrs->{ $attr } }
      }

      push @use_attrs, sprintf '%s="%s"', $attr, $value;
   }

   my $output = join SPC, @use_attrs;

   $output  = " ${output}" if length $output;
   $output .= " ${javascript}" if $javascript;
   return $output;
}

sub quote_single ($) {
  local ($_) = $_[ 0 ];

  s{ ([\\']) }{\\$1}gmx; #'])}emacs

  return qq('$_');
}

sub ucc_widget ($) {
   my $widget = shift;

   if ($widget ne lc $widget) {
      $widget =~ s{ :: }{_}gmx; $widget = ucfirst $widget;

      my @parts = $widget =~ m{ ([A-Z][a-z]*) }gmx;

      $widget = lc join q(_), @parts;
   }

   return $widget;
}

# Private functions
sub _merge_hashes {
   my ($left, $right) = @_; my %newhash;

   for my $leftkey (keys %{ $left }) {
      if (exists $right->{ $leftkey }) {
         $newhash{ $leftkey }
            = merge( $left->{ $leftkey }, $right->{ $leftkey } );
      }
      else { $newhash{ $leftkey } = clone( $left->{ $leftkey } ) }
   }

   for my $rightkey (keys %{ $right }) {
      unless (exists $left->{ $rightkey }) {
         $newhash{ $rightkey } = clone( $right->{ $rightkey } );
      }
   }

   return \%newhash;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Util - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Util;
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
