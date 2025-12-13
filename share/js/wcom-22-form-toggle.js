/** @file HTML Forms - Toggle
    @classdesc Toggles field visibility based on the values of other fields
    @author pjfl@cpan.org (Peter Flanigan)
    @version 0.1.93
*/
WCom.Form.Toggle = (function() {
   const dsName = 'toggleConfig';
   const triggerClass = 'toggle';
   const idPrefix = WCom.Form.Util.wrapperIdPrefix;
   const animate = function(el, method) {
      if (method == 'hide') {
         el.animate({ opacity: 0 }, { duration: 800, fill: 'forwards' });
         setTimeout(function() { el.classList.add('hide') }, 850);
      }
      else {
         if (el.classList.contains('hide')) {
            el.style.opacity = 0;
            el.classList.remove('hide');
            el.animate({ opacity: 1 }, { duration: 800, fill: 'forwards' });
         }
      }
   };
   const fireHandler = function(el) {
      const tagName = el.tagName.toLowerCase();
      const type = el.type ? el.type.toLowerCase() : '';
      if (type != 'radio') {
         if (tagName == 'button' || type == 'submit') return;
         setTimeout(function () {
            if (tagName == 'select' || type == 'hidden' || type == 'text') {
               el.dispatchEvent(new Event('change') );
            }
            else el.dispatchEvent(new Event('click'));
         }, 500);
      }
      else {
         const buttons = document.getElementsByName(el.name);
         if (buttons.length) {
            const checkedButtons = [];
            checkedButtons.push(...buttons.filter(button => button.checked));
            if (!checkedButtons.length) checkedButtons.push(buttons[0]);
            if (checkedButtons[0]) {
               setTimeout(function () {
                  checkedButtons[0].dispatchEvent(new Event('click'));
               }, 500);
            }
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
   let pageLoading;
   let turningOff  = false;
   const toggleFields = function(id) {
      const el = document.getElementById(id);
      if (!el || !el.dataset[dsName]) return;
      const data          = JSON.parse(el.dataset[dsName]);
      const config        = data['config'];
      const noanimate     = data['noanimate'];
      const turnTheseOff  = [];
      const turnTheseOn   = [];
      const updateElement = function(field, method) {
         const el = document.getElementById(idPrefix + field);
         if (el) {
            if (pageLoading || noanimate) {
               if (method == 'hide') el.classList.add('hide');
               else el.classList.remove('hide');
            }
            else animate(el, method);
         }
         const inputEl = document.getElementById(field);
         if (!inputEl) return;
         if (inputEl.classList.contains(triggerClass)) {
            if (method == 'show') turnTheseOn.push(inputEl);
            else turnTheseOff.push(inputEl);
         }
         if (method == 'hide') {
            if (inputEl.getAttribute('required') == 'required') {
               inputEl.removeAttribute('required');
               inputEl.setAttribute('was_required', true);
            }
         }
         else {
            if (inputEl.getAttribute('was_required')) {
               inputEl.setAttribute('required', 'required');
               inputEl.removeAttribute('was_required');
            }
         }
      };
      const tagName = el.tagName.toLowerCase();
      const type = el.type ? el.type.toLowerCase() : '';
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
   const updateInterval = function(id) {
      const period = document.getElementById(id + '_period');
      const unit   = document.getElementById(id + '_unit');
      document.getElementById(id).value = unit.value + ' ' + period.value;
      toggleFields(id + '_period');
   };
   const scan = function(container = document) {
      pageLoading = true;
      fireHandlers(container.getElementsByClassName(triggerClass));
      pageLoading = false;
   };
   return {
      scan: scan,
      toggleFields: toggleFields,
      updateInterval: updateInterval
   };
})();
