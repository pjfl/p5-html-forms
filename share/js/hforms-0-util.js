// Package HForms.Util
if (!window.HForms) window.HForms = {};
HForms.Util = (function () {
   const focusFirst = function() {
      const forms = document.getElementsByTagName('form');
      if (!forms) return;
      for (const form of forms) {
         if (form.className != 'classic') continue;
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
   const updateTimeWithZone = function(id) {
      const hours = document.getElementById(id + '_hours').value;
      const mins  = document.getElementById(id + '_mins').value;
      const zone  = document.getElementById(id + '_zone').value;
      document.getElementById(id).value = hours + ':' + mins + ' ' + zone;
   };
   const wrapperIdPrefix = 'field_';
   onReady(function(event) { focusFirst() });
   return {
      focusFirst: focusFirst,
      onReady: onReady,
      updateTimeWithZone: updateTimeWithZone,
      wrapperIdPrefix: wrapperIdPrefix
   };
})();
