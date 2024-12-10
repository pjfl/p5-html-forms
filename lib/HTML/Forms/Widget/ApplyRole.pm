package HTML::Forms::Widget::ApplyRole;

use Class::Load            qw( load_optional_class );
use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use HTML::Forms::Util      qw( cc_widget );
use Unexpected::Functions  qw( throw );
use Moo::Role;

requires qw( widget_name_space );

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Widget::ApplyRole - Applies widget roles

=head1 Synopsis

   use Moo;

   with 'HTML::Forms::Widget::ApplyRole';

=head1 Description

Applies widget roles

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item apply_widget_role

=cut

sub apply_widget_role {
   my ($self, $target, $widget_name, $dir) = @_;

   my $role = $self->get_widget_role( $widget_name, $dir );

   throw '[_1] widget [_2] not found', [ $dir, $widget_name ] unless $role;

   Role::Tiny->apply_roles_to_object( $target, $role );

   return;
}

=item get_field_trait

=cut

sub get_field_trait {
   my ($self, $trait) = @_;

   my $role = $self->get_widget_role( "Trait::${trait}", 'Field' );

   throw '[_1] widget [_2] not found', [ 'Field::Trait', $trait ] unless $role;

   return $role;
}

=item get_widget_role

=cut

sub get_widget_role {
   my ($self, $widget_name, $dir) = @_;

   my $widget_class = cc_widget $widget_name;
   my $ldir         = $dir ? "::${dir}::" : '::';
   my @name_spaces  = @{ $self->widget_name_space };

   push @name_spaces, 'HTML::Forms::Widget', 'HTML::FormsX::Widget';

   my @classes;

   push @classes, $widget_class if $widget_class =~ s{ \A \+ }{}mx;

   for my $ns (@name_spaces) {
      push @classes,  $ns . $ldir . $widget_class;
   }

   for my $class (@classes) {
      return $class if load_optional_class( $class );
   }

   return;
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo::Role>

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
