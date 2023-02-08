package HTML::Forms::Render::ToggleJs;

use English                qw( -no_match_vars );
use HTML::Forms::Constants qw( NUL );
use JSON::MaybeXS          qw( encode_json );
use Moo::Role;

my $JAVASCRIPT = do { local $RS = undef; <DATA> };

before 'render' => sub {
   my $self = shift;

   return unless $self->render_js_after;

   my $after = $self->get_tag('after');

   $self->set_tag( after => $after . $self->render_toggle_js );
   return;
};

sub render_toggle_js {
   my $self = shift;

   return $JAVASCRIPT;
}

use namespace::autoclean;

1;

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Render::ToggleJs - Generates markup for and processes input from HTML forms

=head1 Synopsis

   use HTML::Forms::Render::ToggleJs;
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
   HForms.Toggle = (function() {
      const animate = function(el, method) {
         const options = { duration: 800, fill: 'forwards' };
         if (method == 'hide') {
            el.animate({ opacity: 0 }, options);
            el.style.display = 'none';
         }
         else {
            el.style.opacity = 0;
            el.style.display = '';
            el.animate({ opacity: 1 }, options);
         }
      };
      const filterChecked = function(els) {
         const checked = [];
         if (!els || els.length < 1) return checked;
         for (const el of els) { if (el.checked) checked.push(el); }
         return checked;
      }
      const fireHandler = function(el) {
         const tagName = el.tagName.toLowerCase();
         const type    = el.type ? el.type.toLowerCase() : '';
         if (type != 'radio') {
            if (tagName == 'button' || type == 'submit') return;
            if (tagName == 'select' || type == 'hidden' || type == 'text') {
               if (el.onchange) el.onchange();
            }
            else if (el.onclick) { el.onclick(); }
         }
         else {
            const buttons = document.getElementsByName(el.name);
            const checkedButtons = [];
            if (buttons.length) {
               checkedButtons.push(...filterChecked(buttons));
               if (!checkedButtons.length) checkedButtons.push(buttons[0]);
               if (checkedButtons[0].onclick) checkedButtons[0].onclick();
            }
         }
      };
      const fireHandlers = function(toggles) {
         for (const toggle of toggles) {
            for (const el of [ toggle, ...toggle.children ]) fireHandler(el);
         }
      };
      const enabledCheckboxes = function(el, config) {
         if (el.checked) return config['-checked'] || [];
         return config['-unchecked'] || [];
      };
      const originals = {};
      const enabledHiddens = function(el, config) {
         const field = config['-changed'];
         if (field) {
            if (!originals[field] || el.value == originals[field]) {
               originals[field] = el.value;
               return [];
            }
            return field;
         }
         if (el.value && config['-set']) return config['-set'];
         return config['-unset'] || [];
      };
      const configValue = function(el, config, isFirst) {
         if (config[el.value]) return config[el.value];
         if (isFirst() && config['-first']) return config['-first'];
         if (config['-other']) return config['-other'];
         return [];
      };
      const enabledRadios = function(el, config) {
         if (!el.checked) return [];
         return configValue(el, config, function() {
            const firstRadio = (document.getElementsByName(this.name))[0];
            return this == firstRadio;
         }.bind(el));
      };
      const enabledSelects = function(el, config) {
         return configValue(el, config, function() {
             return this.selectedIndex == 0;
         }.bind(el));
      };
      const getEnabled  = {
         checkbox: enabledCheckboxes,
         hidden:   enabledHiddens,
         radio:    enabledRadios,
         select:   enabledSelects,
         text:     enabledHiddens
      };
      let pageLoading = true;
      let turningOff  = false;
      const toggleFields = function(el) {
         const dataset       = JSON.parse(el.dataset.toggleConfig);
         const config        = dataset['config'];
         const turnTheseOff  = [];
         const turnTheseOn   = [];
         const updateElement = function(field, method) {
            const el = document.getElementById('field_' + field);
            if (el.classList.contains('toggle')) {
               if (method == 'show') turnTheseOn.push(el);
               else turnTheseOff.push(el);
            }
            if (pageLoading) {
               if (method == 'hide') el.style.display = 'none';
               else el.style.display = '';
            }
            else animate(el, method);
         };
         const tagName = el.tagName.toLowerCase();
         const type    = el.type ? el.type.toLowerCase() : '';
         const enabledFields
            = type    in getEnabled ? getEnabled[type](el, config)
            : tagName in getEnabled ? getEnabled[tagName](el, config)
            : [];

         if (turningOff) {
            for (const field of enabledFields) updateElement(field, 'hide');
         }
         else {
            for (const fields of Object.values(config)) {
               for (const field of fields) {
                  const method = enabledFields.includes(field) ? 'show' : 'hide';
                  updateElement(field, method);
               }
            }
            fireHandlers(turnTheseOn);
         }
         turningOff = true;
         fireHandlers(turnTheseOff);
         turningOff = false;
      };

      return {
         initialise: function() {
            HForms.Util.onReady(function() {
               fireHandlers(document.getElementsByClassName('toggle'));
               pageLoading = false;
            });
         },
         toggleFields: toggleFields
      };
   })();
   HForms.Toggle.initialise();
</script>
