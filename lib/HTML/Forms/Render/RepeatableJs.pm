package HTML::Forms::Render::RepeatableJs;

use namespace::autoclean;

use English                qw( -no_match_vars );
use HTML::Forms::Constants qw( NUL );
use JSON::MaybeXS          qw( encode_json );
use Moo::Role;

sub render_repeatable_js {
   my $self = shift;

   return NUL unless $self->has_for_js;

   my $for_js = $self->for_js;

   my (%html, %index, %level);

   for my $key (keys %{$for_js}) {
      $html{$key}  = $for_js->{$key}->{html};
      $index{$key} = $for_js->{$key}->{index};
      $level{$key} = $for_js->{$key}->{level};
   }

   my $html_str  = encode_json( \%html );
   my $index_str = encode_json( \%index );
   my $level_str = encode_json( \%level );
   my $js        = do { local $RS = undef; <DATA> };

   return sprintf $js, $html_str, $index_str, $level_str;
}

1;

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Render::RepeatableJs - Generates markup for and processes input from HTML forms

=head1 Synopsis

   use HTML::Forms::Render::RepeatableJs;
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

__DATA__
<script>
$(document).ready(function() {
   var rep_html  = %s;
   var rep_index = %s;
   var rep_level = %s;
   $('.add_element').click(function() {
      // get the repeatable id
      var data_rep_id = $(this).attr('data-rep-id');
      // create a regex out of index placeholder
      var level = rep_level[data_rep_id]
      var re = new RegExp('\{index-' + level + '\}',"g");
      // replace the placeholder in the html with the index
      var index = rep_index[data_rep_id];
      var html = rep_html[data_rep_id];
      html = html.replace(re, index);
      // escape dots in element id
      var esc_rep_id = data_rep_id.replace(/[.]/g, '\\\\.');
      // append new element in the 'controls' div of the repeatable
      var rep_controls = $('#' + esc_rep_id + ' > .controls');
      rep_controls.append(html);
      // increment index of repeatable fields
      index++;
      rep_index[data_rep_id] = index;
   });

   $(document).on('click', '.rm_element', function(event) {
      cont = confirm('Remove?');
      if (cont) {
         var id = $(this).attr('data-rep-elem-id');
         var esc_id = id.replace(/[.]/g, '\\\\.');
         var rm_elem = $('#' + esc_id);
         rm_elem.remove();
      }
      event.preventDefault();
   });
});
</script>
