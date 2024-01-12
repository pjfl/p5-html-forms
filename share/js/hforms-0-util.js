// Package HForms.Util
if (!window.HForms) window.HForms = {};
HForms.Util = (function () {
   const formClassName = 'classic';
   const wrapperIdPrefix = 'field_';
   const animateButtons = function(form) {
      const selector = 'div.input-button button';
      for (const el of form.querySelectorAll(selector)) {
         if (el.getAttribute('movelistener')) continue;
         el.addEventListener('mousemove', function(event) {
            const rect = el.getBoundingClientRect();
            const x = Math.floor(event.pageX - (rect.left + window.scrollX));
            const y = Math.floor(event.pageY - (rect.top + window.scrollY));
            el.style.setProperty('--x', x + 'px');
            el.style.setProperty('--y', y + 'px');
         });
         el.setAttribute('movelistener', true);
      }
   };
   const _fieldMap = {};
   const _setFieldMap = function(targetId, fieldId) {
      _fieldMap[targetId] ||= {};
      _fieldMap[targetId][fieldId] = document.getElementById(fieldId).value;
   }
   const _allOk = function(target) {
      const depends = target.getAttribute('data-field-depends') || '';
      for (const fieldId of depends.split(/ /)) {
         if (!_fieldMap[target.id][fieldId]) return false;
      }
      return true;
   };
   const fieldChange = function(targetId, fieldId) {
      _setFieldMap(targetId, fieldId);
      const target = document.getElementById(targetId);
      if (_allOk(target)) target.removeAttribute('disabled');
      else target.setAttribute('disabled', 'disabled');
   };
   const focusFirst = function(form) {
      const selector = 'div.input-field:not(.input-hidden) input';
      const field = form.querySelector(selector);
      if (field) { field.focus() }
   };
   const onReady = function(callback) {
      if (document.readyState != 'loading') callback();
      else if (document.addEventListener)
         document.addEventListener('DOMContentLoaded', callback);
      else document.attachEvent('onreadystatechange', function() {
         if (document.readyState == 'complete') callback();
      });
   };
   const scan = function(className = formClassName) {
      const forms = document.getElementsByTagName('form');
      if (!forms) return;
      for (const form of forms) {
         if (form.className == className) {
            focusFirst(form);
            animateButtons(form);
         }
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
   const showIfRequired = function(url, valueFieldName, toggleFieldNames) {
      const target = new URL(url);
      const field = document.getElementById(valueFieldName);
      target.searchParams.set('value', field.value);
      _showIfRequired(target, toggleFieldNames);
   };
   const unrequire = function(fieldNames) {
      for (name of fieldNames) {
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
   }
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
      for (const span of parent.querySelectorAll('.alert-error')) {
         parent.removeChild(span);
      }
      for (const reason of object.reason) {
         const error = document.createElement('span');
         error.className = 'alert alert-error';
         error.appendChild(document.createTextNode(reason));
         parent.appendChild(error);
      }
   };
   const validateField = function(url, fieldId) {
      const field = document.getElementById(fieldId);
      url = new URL(url.replace(/\*/, field.form.id).replace(/\*/, fieldId));
      url.searchParams.set('value', field.value);
      _validateField(url, field);
   };
   onReady(function(event) { scan() });
   return {
      fieldChange: fieldChange,
      onReady: onReady,
      scan: scan,
      showIfRequired: showIfRequired,
      unrequire: unrequire,
      updateDigits: updateDigits,
      updateTimeWithZone: updateTimeWithZone,
      validateField: validateField,
      wrapperIdPrefix: wrapperIdPrefix
   };
})();
