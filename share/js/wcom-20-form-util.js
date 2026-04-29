/** @file HTML Forms - Utilities
    @classdesc Exports functions used by the other HTML Forms Modules
    @author pjfl@cpan.org (Peter Flanigan)
    @version 0.2.23
*/
if (!WCom.Form) WCom.Form = {};
WCom.Form.Util = (function () {
   const defaultFormClass = 'classic';
   const wrapperIdPrefix = 'field_';
   /** @class
       @classdesc Form utility methods
       @alias Form/Util
   */
   class Util {
      /** @constructs
          @desc Constructs the util object.
      */
      constructor() {
         this.domWait = 0.5;
         this.fieldMap = {};
      }
      /** @function
          @desc Enables/disables elements based on the values of other elements
          @param {object} options
          @property {string} options.id If this field has a value enable the
             target ids if all of their dependent fields also have a value
          @property {array} options.targetIds Element ids to be enabled/disabled
      */
      fieldChange(options) {
         const { id, targetIds } = options;
         for (const targetId of targetIds) {
            this._setFieldMap(targetId, id);
            const target = document.getElementById(targetId);
            if (!target) continue;
            if (this._allOk(target)) target.removeAttribute('disabled');
            else target.setAttribute('disabled', 'disabled');
         }
      }
      _allOk(target) {
         const depends = target.getAttribute('data-field-depends') || '';
         for (const fieldId of depends.split(/ /)) {
            if (fieldId.match(/^!/)) {
               if (this.fieldMap[target.id][fieldId.replace(/!/, '')])
                  return false;
            }
            else if (!this.fieldMap[target.id][fieldId]) return false;
         }
         return true;
      }
      _setFieldMap(targetId, fieldId) {
         const value = document.getElementById(fieldId).value;
         this.fieldMap[targetId] ||= {};
         this.fieldMap[targetId][fieldId] = value;
      }
      /** @function
          @desc Focuses the the first suitable field on the form
          @param {element} form Select the first focusable field from this form
      */
      focusFirst(form) {
         const selector = 'div.input-field:not(.input-hidden) input, div.input-field:not(.input-hidden) select';
         const field = form.querySelector(selector);
         if (field) {
            setTimeout(function() { field.focus() }, 1000 * this.domWait);
         }
      }
      /** @function
          @desc Displays a password strength meter
          @param {string} id The id of the password field
      */
      passwordStrength(options) {
         const { id } = options;
         if (!id) return;
         const field = document.getElementById(id);
         if (!field) return;
         const wrapperId = wrapperIdPrefix + id;
         const wrapper = document.getElementById(wrapperId);
         if (!wrapper) return;
         const meterId = `${id}-meter`;
         const oldMeter = document.getElementById(meterId);
         const meterAttr = { className: 'alert alert-info', id: meterId };
         const value = field.value;
         let score = -2;
         if (value.match(/[a-z]/) && value.match(/[A-Z]/)) { score++ }
         if (value.match(/[0-9]/)) { score++ }
         if (value.match(/[^a-zA-Z0-9]/)) { score++ }
         if (value.length >= 5) { score += value.length - 4 }
         if (score < 0) { score = 0 }
         if (score > 10) { score = 10 }
         const states = [];
         if (score == 0) { states.push('off', 'off', 'off') }
         else if (score > 0 && score < 4) { states.push('on', 'off', 'off') }
         else if (score > 3 && score < 8) { states.push('on', 'on', 'off') }
         else if (score > 7) { states.push('on', 'on', 'on')}
         const content = [this.h.span({}, ['Strength', this.h.frag('&nbsp;')])];
         for (const state of states) {
            const star = this.h.frag('&#9733');
            content.push(this.h.span({ className: `star ${state}` }, star));
         }
         const newMeter = this.h.div(meterAttr, content);
         this.addOrReplace(wrapper, newMeter, oldMeter);
      }
      /** @function
          @desc Toggles the field type between 'password' and 'text'
          @param {string} id The id of the password field
      */
      passwordReveal(id) {
         const field = document.getElementById(id);
         if (!field) return;
         if (!field.getAttribute('leavelistener')) {
            const handler = function(event) { field.type = 'password' };
            field.addEventListener('mouseleave', handler);
            field.setAttribute('leavelistener', true);
         }
         field.type = 'text';
      }
      /** @function
          @desc Shows/hides fields depending other fields current values
          @param {object} options
          @property {string} options.id This field value is set to the server.
             Based on the result the target ids are show/hidden
          @property {array} options.targetIds Element ids to be show/hide
          @property {string} options.url Server endpoint used to test the
             field value
      */
      showIfRequired(options) {
         const { id, targetIds, url } = options;
         const target = new URL(url);
         const field = document.getElementById(id);
         target.searchParams.set('value', field.value);
         this._showIfRequired(target, targetIds);
      }
      async _showIfRequired(url, toggleFieldNames) {
         const response = await fetch(url, { method: 'GET' });
         const object = await response.json();
         for (const name of toggleFieldNames) {
            const toggleField = document.getElementById(wrapperIdPrefix + name);
            const inField = document.getElementById(name);
            const options = { duration: 800, fill: 'forwards' };
            if (object['found']) {
               if (inField && inField.getAttribute('wasrequired')) {
                  inField.setAttribute('required', 'required');
                  inField.removeAttribute('wasrequired');
               }
               toggleField.style.opacity = 0;
               toggleField.classList.remove('hide');
               toggleField.animate({ opacity: 1 }, options);
            }
            else {
               toggleField.animate({ opacity: 0 }, options);
               setTimeout(function() {toggleField.classList.add('hide')}, 850);
               if (inField && inField.getAttribute('required') == 'required') {
                  inField.removeAttribute('required');
                  inField.setAttribute('wasrequired', true);
               }
            }
         }
      }
      /** @function
          @desc Marks selected fields as no longer required
          @param {object} options
          @property {array} options.targetIds Element ids to require/unrequire
      */
      unrequire(options) {
         const { targetIds } = options;
         for (name of targetIds) {
            const field = document.getElementById(name);
            if (field.getAttribute('required') == 'required') {
               field.removeAttribute('required');
               field.setAttribute('wasrequired', true);
            }
         }
      }
      /** @function
          @desc Updates the hidden field associated with a list of digit fields
          @param {string} id Id of the hidden element to update
          @param {integer} index Index of the digit to operate on
      */
      updateDigits(id, index) {
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
            else inputEl = this._nextInputField(hidden);
         }
         if (inputEl) {
            inputEl.focus();
            if (inputEl.select) inputEl.select();
         }
      }
      _nextInputField(current) {
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
      }
      /** @function
          @desc Update a list of values from a comma separated string of values
          @param {string} options
       */
      updateList(options) {
         const id = '_' + options.target + '-group';
         const current = document.getElementById(id);
         const parent = current.parentNode;
         const group = this.h.ul({ id, className: 'selectmany-group' });
         const height = current.style['max-height'];
         if (height) group.style['max-height'] = height;
         const labelAttr = { className: 'item-label' };
         const tuples = [];
         for (const value of options.value.split(/,/)) {
            tuples.push([options.lookup[value], value]);
         }
         const values = [];
         for (const t of tuples.sort((a,b) => (a < b ? -1 : (a > b ? 1 : 0)))) {
            values.push(t[1]);
         }
         let nextOptionId = 0;
         for (const value of values) {
            const id = '_' + options.target + '-' + nextOptionId;
            const label = this.h.label(labelAttr, options.lookup[value]);
            const hiddenAttr = { id, name: options.target, value };
            const item = this.h.li({}, [label, ht.hidden(hiddenAttr)])
            group.appendChild(item);
            nextOptionId++;
         }
         parent.replaceChild(group, current);
      }
      /** @function
          @desc Updates datetime field from the compound digit fields
          @param {string} id Id of the element to update from the hours,
             minutes, and timezone fields
      */
      updateTimeWithZone(id) {
         const hours = document.getElementById(id + '_hours').value;
         const mins  = document.getElementById(id + '_mins').value;
         const zone  = document.getElementById(id + '_zone').value;
         document.getElementById(id).value = hours + ':' + mins + ' ' + zone;
      }
      /** @function
          @desc Validates the specified field
          @param {object} options
          @property {string} id Id of the field to validate
          @property {string} url Server endpoint used to validate form fields
      */
      validateField(options) {
         let { id, itemId, url } = options;
         const field = document.getElementById(id);
         url = new URL(url.replace(/\*/, field.form.id).replace(/\*/, id));
         url.searchParams.set('value', field.value);
         url.searchParams.set('item-id', itemId);
         this._validateField(url, field);
      }
      async _validateField(url, field) {
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
      }
   }
   Object.assign(Util.prototype, WCom.Util.Markup);
   const util = new Util();
   /** @module Form/Util
       @desc Exports form related static functions.
   */
   return {
      /** @constant
          @desc Default form class to scan for. Defaults to 'classic'
      */
      defaultFormClass,
      /** @function
          @see {@link Form/Util#fieldChange|Field change}
          @param {object} options
      */
      fieldChange: util.fieldChange.bind(util),
      /** @function
          @see {@link Form/Util#focusFirst|Focus first}
          @param {element} form
      */
      focusFirst: util.focusFirst.bind(util),
      /** @function
          @see {@link Form/Util#passwordStrength|Password strength}
          @param {object} options
      */
      passwordStrength: util.passwordStrength.bind(util),
      /** @function
          @see {@link Form/Util#passwordReveal|Password reveal}
          @param {string} id
      */
      passwordReveal: util.passwordReveal.bind(util),
      /** @function
          @see {@link Form/Util#showIfRequired|Show if required}
          @param {object} options
      */
      showIfRequired: util.showIfRequired.bind(util),
      /** @function
          @see {@link Form/Util#unrequire Unrequire}
          @param {object} options
      */
      unrequire: util.unrequire.bind(util),
      /** @function
          @see {@link Form/Util#updateDigits|Update digits}
          @param {string} id
          @param {integer} index
      */
      updateDigits: util.updateDigits.bind(util),
      /** @function
          @see {@link Form/Util#updateList|Update list}
          @param {object} options
      */
      updateList: util.updateList.bind(util),
      /** @function
          @see {@link Form/Util#updateTimeWithZone|Update time}
          @param {string} id
      */
      updateTimeWithZone: util.updateTimeWithZone.bind(util),
      /** @function
          @see {@link Form/Util#validateField|Validate field}
      */
      validateField: util.validateField.bind(util),
      /** @constant
          @desc Prefix used when naming fields. Defaults to 'field_'
          @param {object} options
      */
      wrapperIdPrefix
   };
})();
