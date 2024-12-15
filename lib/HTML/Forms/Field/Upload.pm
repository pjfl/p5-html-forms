package HTML::Forms::Field::Upload;

use HTML::Forms::Constants qw( META TRUE );
use HTML::Forms::Types     qw( Int Maybe );
use Scalar::Util           qw( reftype );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::NoValue';

has 'max_size' => is => 'rw', isa => Maybe[Int], default => 1048576;

has 'min_size' => is => 'rw', isa => Maybe[Int], default => 1;

has '+type_attr' => default => 'file';

has '+widget' => default => 'Upload';

has '+wrapper_class' => default => 'input-file';

our $class_messages = {
   'upload_file_empty'     => 'File uploaded is empty',
   'upload_file_not_found' => 'File not found for upload field',
   'upload_file_too_big'   => 'File is too big (> [_1] bytes)',
   'upload_file_too_small' => 'File is too small (< [_1] bytes)',
};

sub get_class_messages {
   my $self = shift;

   return { %{ $self->next::method }, %{ $class_messages  } };
}

sub validate {
   my $self   = shift;
   my $upload = $self->value;
   my $size   = 0;

   if (blessed $upload && $upload->can('size')) { $size = $upload->size }
   elsif (is_real_fh( $upload )) { $size = -s $upload }
   else {
      return $self->add_error($self->get_message('upload_file_not_found'));
   }

   return $self->add_error($self->get_message('upload_file_empty'))
      unless $size > 0;

   if (defined $self->max_size && $size > $self->max_size) {
      $self->add_error(
         $self->get_message('upload_file_too_big'), $self->max_size
      );
   }

   if (defined $self->min_size && $size < $self->min_size) {
      $self->add_error(
         $self->get_message('upload_file_too_small'), $self->min_size
      );
   }

   return;
}

sub _is_real_fh {
   my $fh      = shift;
   my $reftype = reftype $fh or return;

   return unless $reftype eq 'IO' or $reftype eq 'GLOB' && *{$fh}{IO};

   my $m_fileno = $fh->fileno;

   return unless defined $m_fileno;
   return unless $m_fileno >= 0;

   my $f_fileno = fileno($fh);

   return unless defined $f_fileno;
   return unless $f_fileno >= 0;
   return TRUE;
}

use namespace::autoclean -except => META;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Upload - File upload

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'Upload';

=head1 Description

File upload

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item max_size

=item min_size

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item get_class_messages

=item validate

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::Forms::Field::NoValue>

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
