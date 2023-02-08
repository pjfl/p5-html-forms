package HTML::Forms::Render::RepeatableJs;

use English                qw( -no_match_vars );
use HTML::Forms::Constants qw( NUL );
use JSON::MaybeXS          qw( encode_json );
use Moo::Role;

my $JAVASCRIPT = do { local $RS = undef; <DATA> };

before 'render' => sub {
   my $self = shift;

   return unless $self->render_js_after;

   my $after = $self->get_tag('after');

   $self->set_tag( after => $after . $self->render_repeatable_js );
   return;
};

sub render_repeatable_js {
   my $self = shift;

   return NUL unless $self->has_for_js;

   my (%html, %index, %level);

   for my $name (keys %{$self->for_js}) {
      my $field = $self->for_js->{$name};

      $html{$name}  = $field->{html};
      $index{$name} = $field->{index};
      $level{$name} = $field->{level};
   }

   my $html_str  = encode_json( \%html );
   my $index_str = encode_json( \%index );
   my $level_str = encode_json( \%level );

   return sprintf "${JAVASCRIPT}", $html_str, $index_str, $level_str;
}

use namespace::autoclean;

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
   if (!window.HForms) window.HForms = {};
   HForms.Repeatable = (function() {
      const addRemoveHandlers = function() {
         const rmElems = document.getElementsByClassName('remove-repeatable');
         for (const el of rmElems) {
            el.onclick = function(event) {
               if (confirm('Remove?')) {
                  const repElemId = this.dataset.repeatableElementId;
                  document.getElementById('field_' + repElemId).remove();
               }
               event.preventDefault();
            }.bind(el);
         };
      };
      const addAddHandlers = function(htmls, indexes, levels) {
         const addElems = document.getElementsByClassName('add-repeatable');
         for (const el of addElems) {
            el.onclick = function(event) {
               const repId    = this.dataset.repeatableId;
               const html     = htmls[repId];
               let   index    = indexes[repId];
               const level    = levels[repId]
               const wrapper  = document.getElementById('field_' + repId);
               const controls = wrapper.getElementsByClassName('controls');
               const re       = new RegExp('\{index-' + level + '\}',"g");
               controls[0].innerHTML += html.replace(re, index);
               index++;
               indexes[repId] = index;
               addRemoveHandlers();
               event.preventDefault();
            }.bind(el);
         }
      };
      return {
         initialise: function(htmls, indexes, levels) {
            addAddHandlers(htmls, indexes, levels);
            addRemoveHandlers();
         }
      };
   })();
   HForms.Repeatable.initialise(%s, %s, %s);
</script>
