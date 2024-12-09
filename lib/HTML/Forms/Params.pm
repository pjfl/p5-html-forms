package HTML::Forms::Params;

use HTML::Forms::Constants qw( DOT EXCEPTION_CLASS NUL );
use HTML::Forms::Types     qw( Str );
use Ref::Util              qw( is_arrayref is_hashref );
use Unexpected::Functions  qw( throw );
use Moo;

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Params - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Params;
   # Brief but working code examples

=head1 Description

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item separator

=cut

has 'separator' => is => 'rw', isa => Str, default => DOT;

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item collapse_hash

=cut

sub collapse_hash {
   my $self = shift;
   my $deep = shift;
   my $flat = {};

   $self->_collapse_hash($deep, $flat, ());

   return $flat;
}

=item expand_hash

=cut

sub expand_hash {
   my ($self, $flat, $sep) = @_;

   $sep //= $self->separator;

   my $deep = {};

   for my $name (keys %{ $flat }) {
      my ($first, @segments) = $self->split_name( $name, $sep );
      my $box_ref = \$deep->{ $first };

      for (@segments) {
         if (m{ \A ( 0 | [1-9] \d* ) \z }mx) {
            ${ $box_ref } = [] unless defined ${ $box_ref };
            throw 'HFs: param clash for [_1]=[_2]', [ $name, $_ ]
               unless is_arrayref ${ $box_ref };
            $box_ref = \( ${ $box_ref }->[ $1 ] );
         }
         else {
            s{ \\(.) }{$1}gmx if $sep;  # Remove escaping
            ${ $box_ref } = {} unless defined ${ $box_ref };
            ${ $box_ref } = { NUL() => ${ $box_ref } } if !ref ${ $box_ref };
            throw 'HFs: param clash for [_1]=[_2]', [ $name, $_ ]
               unless is_hashref ${ $box_ref };
            $box_ref = \( ${ $box_ref }->{ $_ } );
         }
      }

      if (defined ${ $box_ref }) {
         throw 'HFs: param clash for [_1] value [_2]',
            [ $name, $flat->{$name} ] if is_hashref ${ $box_ref };
         $box_ref = \( ${ $box_ref }->{ NUL() } );
      }

      ${ $box_ref } = $flat->{ $name };
   }

   return $deep;
}

=item join_name

=cut

sub join_name {
   my ($self, @array) = @_;

   return join substr( $self->separator, 0, 1 ), @array;
}

=item split_name

=cut

sub split_name {
   my ($self, $name, $sep) = @_;

   $sep ||= $self->separator;

   if ($sep eq '[]') {
      return grep { defined } ($name =~ m{ \A (\w+) | \[ (\w+) \] }gmx );
   }

   # These next two regexes are the escaping aware equivalent to the following:
   # my ($first, @segments) = split(/\./, $name, -1);

   # m// splits on unescaped '.' chars. Can't fail b/c \G on next
   # non ./ * -> escaped anything -> non ./ *
   $sep = "\Q${sep}";
   $name =~ m{ \A ( [^\\$sep]* (?: \\(?:.|$) [^\\$sep]* )* ) }gmx;

   my $first = $1; $first =~ s{ \\(.) }{$1}gmx; # Remove escaping
   # . -> ( non ./ * -> escaped anything -> non ./ * )
   my (@segments) = $name =~
      m{ \G (?:[$sep]) ( [^\\$sep]* (?: \\(?:.|$) [^\\$sep]* )* ) }gmx;

   # Escapes removed later, can be used to avoid using as array index
   return ($first, @segments);
}

# Private methods
sub _collapse_hash {
   my ($self, $deep, $flat, @segments) = @_;

   if (!ref $deep) {
      my $name = $self->join_name( @segments );

      $flat->{ $name } = $deep;
   }
   elsif (is_hashref $deep) {
      for (keys %{ $deep }) {
         # Escape \ and separator chars (once only, at this level)
         my $name = $_;

         if (defined (my $sep = $self->separator)) {
            $sep = "\Q${sep}"; $name =~ s{ ([\\$sep]) }{\\$1}gmx;
         }

         $self->_collapse_hash( $deep->{ $_ }, $flat, @segments, $name );
      }
   }
   elsif (is_arrayref $deep) {
      for (0 .. $#$deep) {
         $self->_collapse_hash( $deep->[ $_ ], $flat, @segments, $_ )
            if defined $deep->[ $_ ];
      }
   }
   else {
      throw 'Unknown reference type for [_1]: [_2]',
         [ $self->join_name( @segments ), ref $deep ];
   }
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
