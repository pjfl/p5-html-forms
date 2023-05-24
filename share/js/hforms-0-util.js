// Package HForms.Util
if (!window.HForms) window.HForms = {};
HForms.Util = (function () {
   const wrapperIdPrefix = 'field_';
   async function _showIfRequired(url, toggleFieldNames) {
      const response = await fetch(url, { method: 'GET' });
      const object = await response.json();
      for (const name of toggleFieldNames) {
         const toggleField = document.getElementById(wrapperIdPrefix + name);
         const inputField = document.getElementById(name);
         const options = { duration: 800, fill: 'forwards' };
         if (object['found']) {
            if (inputField.getAttribute('wasrequired')) {
               inputField.setAttribute('required', 'required');
               inputField.removeAttribute('wasrequired');
            }
            toggleField.style.opacity = 0;
            toggleField.classList.remove('hide');
            toggleField.animate({ opacity: 1 }, options);
         }
         else {
            toggleField.animate({ opacity: 0 }, options);
            if (inputField.getAttribute('required') == 'required') {
               inputField.removeAttribute('required');
               inputField.setAttribute('wasrequired', true);
            }
         }
      }
   }
   const focusFirst = function(className) {
      const forms = document.getElementsByTagName('form');
      if (!forms) return;
      for (const form of forms) {
         if (className && form.className != className) continue;
         const selector = 'div.input-field:not(.input-hidden) input';
         const field = form.querySelector(selector);
         if (!field) continue;
         field.focus();
         break;
      }
   };
   const onReady = function(callback) {
      if (document.readyState != 'loading') callback();
      else if (document.addEventListener)
         document.addEventListener('DOMContentLoaded', callback);
      else document.attachEvent('onreadystatechange', function() {
         if (document.readyState == 'complete') callback();
      });
   };
   const showIfRequired = function(url, valueFieldName, toggleFieldNames) {
      const target = new URL(url);
      target.searchParams.set(
         'value', document.getElementById(valueFieldName).value
      );
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
   }
   const updateTimeWithZone = function(id) {
      const hours = document.getElementById(id + '_hours').value;
      const mins  = document.getElementById(id + '_mins').value;
      const zone  = document.getElementById(id + '_zone').value;
      document.getElementById(id).value = hours + ':' + mins + ' ' + zone;
   };
   onReady(function(event) { focusFirst('classic') });
   return {
      focusFirst: focusFirst,
      onReady: onReady,
      showIfRequired: showIfRequired,
      unrequire: unrequire,
      updateTimeWithZone: updateTimeWithZone,
      wrapperIdPrefix: wrapperIdPrefix
   };
})();
