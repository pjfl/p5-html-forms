/** @file HTML Forms - Utilities
    @classdesc Exports functions used by the other HTML Forms Modules
    @author pjfl@cpan.org (Peter Flanigan)
    @version 0.2.7
*/
if (!WCom.Form) WCom.Form = {};
WCom.Form.Util = (function () {
   const defaultFormClass = 'classic';
   const wrapperIdPrefix = 'field_';
   const _fieldMap = {};
   const _setFieldMap = function(targetId, fieldId) {
      _fieldMap[targetId] ||= {};
      _fieldMap[targetId][fieldId] = document.getElementById(fieldId).value;
   }
   const _allOk = function(target) {
      const depends = target.getAttribute('data-field-depends') || '';
      for (const fieldId of depends.split(/ /)) {
         if (fieldId.match(/^!/)) {
            if (_fieldMap[target.id][fieldId.replace(/!/, '')]) return false;
         }
         else if (!_fieldMap[target.id][fieldId]) return false;
      }
      return true;
   };
   const fieldChange = function(options) {
      const { id, targetIds } = options;
      for (const targetId of targetIds) {
         _setFieldMap(targetId, id);
         const target = document.getElementById(targetId);
         if (!target) continue;
         if (_allOk(target)) target.removeAttribute('disabled');
         else target.setAttribute('disabled', 'disabled');
      }
   };
   const focusFirst = function(form) {
      const selector = 'div.input-field:not(.input-hidden) input, div.input-field:not(.input-hidden) select';
      const field = form.querySelector(selector);
      if (field) setTimeout(function() { field.focus() }, 500);
   };
   const revealPassword = function(id) {
      const field = document.getElementById(id);
      if (!field.getAttribute('leavelistener')) {
         const handler = function(event) { field.type = 'password' };
         field.addEventListener('mouseleave', handler);
         field.setAttribute('leavelistener', true);
      }
      field.type = 'text';
   };
   const scan = function(content = document, options = {}) {
      if (WCom.Form.Renderer.scan(content, options)) return;
      const formClass = options.formClass
            ? options.formClass : defaultFormClass;
      const forms = content.querySelector('form.' + formClass);
      if (!forms) return;
      for (const form of forms) {
         WCom.Form.DataStructure.scan(form);
         WCom.Form.Toggle.scan(form);
         WCom.Util.Markup.animateButtons(form, '.input-field button');
         focusFirst(form);
      }
   };
   async function _showIfRequired(url, toggleFieldNames) {
      const response = await fetch(url, { method: 'GET' });
      const object = await response.json();
      for (const name of toggleFieldNames) {
         const toggleField = document.getElementById(wrapperIdPrefix + name);
         const inputField = document.getElementById(name);
         const options = { duration: 800, fill: 'forwards' };
         if (object['found']) {
            if (inputField && inputField.getAttribute('wasrequired')) {
               inputField.setAttribute('required', 'required');
               inputField.removeAttribute('wasrequired');
            }
            toggleField.style.opacity = 0;
            toggleField.classList.remove('hide');
            toggleField.animate({ opacity: 1 }, options);
         }
         else {
            toggleField.animate({ opacity: 0 }, options);
            setTimeout(function() { toggleField.classList.add('hide') }, 850);
            if (inputField &&inputField.getAttribute('required') == 'required'){
               inputField.removeAttribute('required');
               inputField.setAttribute('wasrequired', true);
            }
         }
      }
   };
   const showIfRequired = function(options) {
      const { id, targetIds, url } = options;
      const target = new URL(url);
      const field = document.getElementById(id);
      target.searchParams.set('value', field.value);
      _showIfRequired(target, targetIds);
   };
   const unrequire = function(options) {
      const { targetIds } = options;
      for (name of targetIds) {
         const field = document.getElementById(name);
         if (field.getAttribute('required') == 'required') {
            field.removeAttribute('required');
            field.setAttribute('wasrequired', true);
         }
      }
   };
   const _nextInputField = function(current) {
      const fieldSet = current.parentElement.parentElement;
      const selector = 'input, button, select, textarea';
      const universe = fieldSet.querySelectorAll(selector);
      const list = Array.prototype.filter.call(
         universe, function(item) { return item.tabIndex >= '0' }
      );
      let count = 1;
      let candidate = list[list.indexOf(current) + count];
      while (candidate && candidate.getAttribute('disabled') == 'disabled') {
         candidate = list[list.indexOf(current) + (++count)];
      }
      if (candidate) return candidate;
      return list[0];
   };
   const updateDigits = function(id, index) {
      let count = 0;
      let inputEl;
      let nextEl;
      let target;
      let total = '';
      while (inputEl = document.getElementById(id + '-' + count)) {
         if (count == index) target = inputEl;
         const value = inputEl.value;
         count += 1;
         if (!value) continue;
         if (value.match(/[0-9]/)) total += `${value}`;
         else {
            nextEl = inputEl;
            inputEl.value = '';
         }
      }
      const hidden = document.getElementById(id);
      if (hidden) hidden.value = total;
      if (nextEl) inputEl = nextEl;
      else {
         const sibling = target.nextElementSibling;
         if (sibling) inputEl = sibling;
         else inputEl = _nextInputField(hidden);
      }
      if (inputEl) {
         inputEl.focus();
         if (inputEl.select) inputEl.select();
      }
   };
   const updateList = function(options) {
      const ht = WCom.Util.Markup.h;
      const id = '_' + options.target + '-group';
      const current = document.getElementById(id);
      const parent = current.parentNode;
      const group = ht.ul({ id, className: 'selectmany-group' });
      const height = current.style['max-height'];
      if (height) group.style['max-height'] = height;
      const labelAttr = { className: 'item-label' };
      const tuples = [];
      for (const value of options.value.split(/,/)) {
         tuples.push([options.lookup[value], value]);
      }
      const values = [];
      for (const tuple of tuples.sort((a,b) => (a < b ? -1 : (a > b ? 1 : 0)))){
         values.push(tuple[1]);
      }
      let nextOptionId = 0;
      for (const value of values) {
         const id = '_' + options.target + '-' + nextOptionId;
         const label = ht.label(labelAttr, options.lookup[value]);
         const hiddenAttr = { id, name: options.target, value };
         const item = ht.li({}, [label, ht.hidden(hiddenAttr)])
         group.appendChild(item);
         nextOptionId++;
      }
      parent.replaceChild(group, current);
   };
   const updateTimeWithZone = function(id) {
      const hours = document.getElementById(id + '_hours').value;
      const mins  = document.getElementById(id + '_mins').value;
      const zone  = document.getElementById(id + '_zone').value;
      document.getElementById(id).value = hours + ':' + mins + ' ' + zone;
   };
   async function _validateField(url, field) {
      const response = await fetch(url, { method: 'GET' });
      const object = await response.json();
      if (!object) return;
      const parent = field.parentElement;
      for (const el of parent.querySelectorAll('.alert')) {
         parent.removeChild(el);
      }
      const wrapper = document.createElement('div');
      wrapper.classList.add('alert');
      for (const reason of object.reason) {
         const error = document.createElement('span');
         error.classList.add('alert-error');
         error.appendChild(document.createTextNode(reason));
         wrapper.appendChild(error);
      }
      parent.appendChild(wrapper);
   };
   const validateField = function(options) {
      let { id, url } = options;
      const field = document.getElementById(id);
      url = new URL(url.replace(/\*/, field.form.id).replace(/\*/, id));
      url.searchParams.set('value', field.value);
      _validateField(url, field);
   };
   WCom.Util.Event.registerOnload(scan);
   /** @module Form/Util
       @desc Exports form related static functions
   */
   return {
      /** @function
          @desc Enables/disables elements based on the values of other elements
          @param {object} options
          @property {string} options.id If this field has a value enable the
             target ids if all of their dependent fields also have a value
          @property {array} options.targetIds Element ids to be enabled/disabled
      */
      fieldChange: fieldChange,
      /** @function
          @desc Focuses the the first suitable field on the form
          @param {object} form Select the first focusable field from this form
      */
      focusFirst: focusFirst,
      /** @function
          @desc Toggles the field type between 'password' and 'text'
          @param {string} id The id of the password field
      */
      revealPassword: revealPassword,
      /** @function
          @desc Scans the supplied DOM element for the form's trigger class
          @param {object} content DOM element to scan
          @param {object} options
          @property {string} options.formClass Form class to select. Defaults
             to 'classic'
      */
      scan: scan,
      /** @function
          @desc Shows/hides fields depending other fields current values
          @param {object} options
          @property {string} options.id This field value is set to the server.
             Based on the result the target ids are show/hidden
          @property {array} options.targetIds Element ids to be show/hide
          @property {string} options.url Server endpoint used to test the
             field value
      */
      showIfRequired: showIfRequired,
      /** @function
          @desc Marks selected fields as no longer required
          @param {object} options
          @property {array} options.targetIds Element ids to require/unrequire
      */
      unrequire: unrequire,
      /** @function
          @desc Updates the hidden field associated with a list of digit fields
          @param {string} id Id of the hidden element to update
          @param {integer} index Index of the digit to operate on
      */
      updateDigits: updateDigits,
      /** @function
          @desc Update a list of values from a comma separated string of values
          @param {string} options
       */
      updateList: updateList,
      /** @function
          @desc Updates datetime field from the compound digit fields
          @param {string} id Id of the element to update from the hours,
             minutes, and timezone fields
      */
      updateTimeWithZone: updateTimeWithZone,
      /** @function
          @desc Validates the specified field
          @param {object} options
          @property {string} id Id of the field to validate
          @property {string} url Server endpoint used to validate form fields
      */
      validateField: validateField,
      /** @constant
          @desc Prefix used when naming fields
      */
      wrapperIdPrefix: wrapperIdPrefix
   };
})();
