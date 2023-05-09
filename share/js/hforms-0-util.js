// Package HForms.Util
if (!window.HForms) window.HForms = {};
HForms.Util = (function () {
   async function _showIfRequired(url, toggleField) {
      const response = await fetch(url, { method: 'GET' });
      const object = await response.json();
      if (object['found']) toggleField.classList.remove('hide');
      else toggleField.classList.add('hide');
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
   const showIfRequired = function(url, valueFieldName, toggleFieldName) {
      const target = new URL(url);
      target.searchParams.set(
         'value', document.getElementById(valueFieldName).value
      );
      const toggleField = document.getElementById(toggleFieldName);
      _showIfRequired(target, toggleField);
   };
   const updateTimeWithZone = function(id) {
      const hours = document.getElementById(id + '_hours').value;
      const mins  = document.getElementById(id + '_mins').value;
      const zone  = document.getElementById(id + '_zone').value;
      document.getElementById(id).value = hours + ':' + mins + ' ' + zone;
   };
   const wrapperIdPrefix = 'field_';
   onReady(function(event) { focusFirst('classic') });
   return {
      focusFirst: focusFirst,
      onReady: onReady,
      showIfRequired: showIfRequired,
      updateTimeWithZone: updateTimeWithZone,
      wrapperIdPrefix: wrapperIdPrefix
   };
})();
