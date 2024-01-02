// Package HForms.Util
if (!window.HForms) window.HForms = {};
HForms.Util = (function () {
   const formClassName = 'classic';
   const wrapperIdPrefix = 'field_';
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
            if (inputField &&inputField.getAttribute('required') == 'required'){
               inputField.removeAttribute('required');
               inputField.setAttribute('wasrequired', true);
            }
         }
      }
   };
   const animateButtons = function(form) {
      const selector = 'div.input-button button';
      for (const button of form.querySelectorAll(selector)) {
         button.addEventListener('mousemove', function(event) {
            const rect = button.getBoundingClientRect();
            const x = Math.floor(event.pageX - (rect.left + window.scrollX));
            const y = Math.floor(event.pageY - (rect.top + window.scrollY));
            button.style.setProperty('--x', x + 'px');
            button.style.setProperty('--y', y + 'px');
         });
      }
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
   const updateDigits = function(id, index) {
      let total = '';
      let count = 0;
      let el;
      let target;
      while (el = document.getElementById(id + '-' + count)) {
         if (count == index) target = el;
         const value = el.value;
         total += `${value}`;
         count += 1;
      }
      el = document.getElementById(id);
      if (el) el.value = total;
      const sibling = target.nextElementSibling;
      if (sibling) el = sibling;
      else {
         const universe = document.querySelectorAll(
            'input, button, select, textarea'
         );
         const list = Array.prototype.filter.call(
            universe, function(item) { return item.tabIndex >= '0' }
         );
         const index = list.indexOf(el);
         el = list[index + count + 1] || list[0];
      }
      if (el) {
         el.focus();
         if (el.select) el.select();
      }
   }
   const updateTimeWithZone = function(id) {
      const hours = document.getElementById(id + '_hours').value;
      const mins  = document.getElementById(id + '_mins').value;
      const zone  = document.getElementById(id + '_zone').value;
      document.getElementById(id).value = hours + ':' + mins + ' ' + zone;
   };
   onReady(function(event) { scan() });
   return {
      onReady: onReady,
      scan: scan,
      showIfRequired: showIfRequired,
      unrequire: unrequire,
      updateDigits: updateDigits,
      updateTimeWithZone: updateTimeWithZone,
      wrapperIdPrefix: wrapperIdPrefix
   };
})();
