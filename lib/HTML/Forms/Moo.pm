package HTML::Forms::Moo;

use mro;
use strictures;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE META TRUE );
use HTML::Forms::Meta;
use Ref::Util              qw( is_arrayref );
use Sub::Install           qw( install_sub );
use Unexpected::Functions  qw( throw );

my @banished_keywords = ( META );

my @block_attributes  = qw(  );
my @moo_attributes    = qw( builder clearer coerce handles init_arg is isa
   predicate trigger lazy reader weak_ref writer );
my @page_attributes   = qw(  );

# Public functions
sub default_meta_config () {
   return found_hfs => FALSE;
}

sub import {
   my ($class, @args) = @_;

   my $target = caller;

   for my $want (grep { not $target->can($_) } qw(has)) {
      throw 'Method [_1] not found in class [_2]', [$want, $target];
   }

   my $has = $target->can('has');
   my @target_isa = @{ mro::get_linear_isa($target) };
   my $method = META;
   my $meta;

   if (@target_isa) {
      # Don't add this to a role. The ISA of a role is always empty!
      if ($target->can( $method )) { $meta = $target->$method }
      else {
         my $meta_config = { default_meta_config, target => $target, @args };

         $meta = HTML::Forms::Meta->new($meta_config);
         install_sub { as => $method, into => $target, code => sub {
            return $meta;
         }, };
      }
   }
   else {
      throw 'No meta object' unless $target->can($method);

      $meta = $target->$method;
   }

   my $info = $Role::Tiny::INFO{ $target };
   my $apply = sub { $meta->add_to_apply_list( shift ); return };
   my $rt_info_key = 'non_methods';

   $info->{$rt_info_key}{apply} = $apply if $info;

   install_sub { as => 'apply', into => $target, code => $apply, };

   my $has_block = sub {
      my ($name, %attributes) = @_;

      _assert_no_banished_keywords( $target, $name );
      $has->( $name => _filter_out_block_attributes( %attributes ) );
      $meta->add_to_block_list( { name => $name,
         _validate_and_filter_block_attributes( %attributes ) } );
      return;
   };

   $info->{$rt_info_key}{has_block} = $has_block if $info;

   install_sub { as => 'has_block', into => $target, code => $has_block, };

   my $has_field = sub {
      my ($name, %attributes) = @_;
      my $names = is_arrayref $name ? $name : [ $name ];

      for my $name (@{ $names }) {
         _assert_no_banished_keywords( $target, $name );
         $has->( $name => _filter_out_field_attributes( %attributes ) );
         $meta->add_to_field_list( {
            name => $name,
            _validate_and_filter_field_attributes( %attributes )
         } );
      }

      return;
   };

   $info->{$rt_info_key}{has_field} = $has_field if $info;

   install_sub { as => 'has_field', into => $target, code => $has_field, };

   my $has_page = sub {
      my ($name, %attributes) = @_;
      my $names = is_arrayref $name ? $name : [ $name ];

      for my $name (@{ $names }) {
         _assert_no_banished_keywords( $target, $name );
         $has->( $name => _filter_out_page_attributes( %attributes ) );
         $meta->add_to_page_list( {
            name => $name, _validate_and_filter_page_attributes( %attributes )
         } );
      }

      return;
   };

   $info->{$rt_info_key}{has_page} = $has_page if $info;

   install_sub { as => 'has_page', into => $target, code => $has_page, };

   return;
}

# Private functions
sub _assert_no_banished_keywords {
   my ($target, $name) = @_;

   for my $ban (grep { $_ eq $name } @banished_keywords) {
      throw 'Method [_1] used by class [_2] as an attribute', [ $ban, $target ];
   }

   return;
}

sub _filter_out_block_attributes {
   my %attributes = @_;
   my %filter_key = map { $_ => 1 } @block_attributes;

   return map { ( $_ => $attributes{ $_ } ) }
         grep { not exists $filter_key{ $_ } } keys %attributes;
}

sub _validate_and_filter_block_attributes {
   my (%attributes) = @_;

   my %filtered = map { ( $_ => $attributes{ $_ } ) }
      grep { exists $attributes{ $_ } } @block_attributes, 'required';

   return %filtered;
}

sub _filter_out_field_attributes {
   my %attributes = @_;
   my %filter_key = map { $_ => 1 } @moo_attributes;

   $attributes{is} //= 'ro';

   return map { ( $_ => $attributes{ $_ } ) }
         grep { exists $filter_key{ $_ } } keys %attributes;
}

sub _validate_and_filter_field_attributes {
   my (%attributes) = @_;
   my %filter_key = map { $_ => 1 } @moo_attributes;

   my %filtered = map { ( $_ => $attributes{ $_ } ) }
      grep { not exists $filter_key{ $_ } } keys %attributes;

   return %filtered;
}

sub _filter_out_page_attributes {
   my %attributes = @_;
   my %filter_key = map { $_ => 1 } @page_attributes;

   return map { ( $_ => $attributes{ $_ } ) }
         grep { not exists $filter_key{ $_ } } keys %attributes;
}

sub _validate_and_filter_page_attributes {
   my (%attributes) = @_;

   my %filtered = map { ( $_ => $attributes{ $_ } ) }
      grep { exists $attributes{ $_ } } @page_attributes, 'required';

   return %filtered;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Moo - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Moo;
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
