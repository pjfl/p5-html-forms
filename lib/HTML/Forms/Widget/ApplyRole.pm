package HTML::Forms::Widget::ApplyRole;

use Class::Load            qw( load_optional_class );
use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use HTML::Forms::Util      qw( cc_widget );
use Unexpected::Functions  qw( throw );
use Moo::Role;

requires qw( widget_name_space );

# Public methods
sub apply_widget_role {
   my ($self, $target, $widget_name, $dir) = @_;

   my $role = $self->get_widget_role( $widget_name, $dir );

   throw '[_1] widget [_2] not found', [ $dir, $widget_name ] unless $role;

   Role::Tiny->apply_roles_to_object( $target, $role );

   return;
}

sub get_field_trait {
   my ($self, $trait) = @_;

   my $role = $self->get_widget_role( "Trait::${trait}", 'Field' );

   throw '[_1] widget [_2] not found', [ 'Field::Trait', $trait ] unless $role;

   return $role;
}

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

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Widget::ApplyRole - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Widget::ApplyRole;
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
