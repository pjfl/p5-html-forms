// Package WCom.Form.Util
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
         if (!_fieldMap[target.id][fieldId]) return false;
      }
      return true;
   };
   const fieldChange = function(fieldId, targetIds) {
      for (const targetId of targetIds) {
         _setFieldMap(targetId, fieldId);
         const target = document.getElementById(targetId);
         if (_allOk(target)) target.removeAttribute('disabled');
         else target.setAttribute('disabled', 'disabled');
      }
   };
   const focusFirst = function(form) {
      const selector = 'div.input-field:not(.input-hidden) input';
      const field = form.querySelector(selector);
      if (field) setTimeout(function() { field.focus() }, 500);
   };
   const _repRemoveHandlers = function() {
      const rmElems = document.getElementsByClassName('remove-repeatable');
      for (const el of rmElems) {
         if (el.getAttribute('clicklistener')) continue;
         el.setAttribute('clicklistener', true);
         el.addEventListener('click', function(event) {
            event.preventDefault();
            const repElemId = this.dataset.repeatableElementId;
            if (!repElemId) return;
            const field = document.getElementById(wrapperIdPrefix + repElemId);
            if (field && confirm('Remove?')) field.remove();
         }.bind(el));
      }
   };
   const _repAddHandlers = function(htmls, indexes, levels) {
      const addElems = document.getElementsByClassName('add-repeatable');
      for (const el of addElems) {
         if (el.getAttribute('clicklistener')) continue;
         el.setAttribute('clicklistener', true);
         el.addEventListener('click', function(event) {
            event.preventDefault();
            const repId = this.dataset.repeatableId;
            if (!repId) return;
            const wrapper = document.getElementById(wrapperIdPrefix + repId);
            if (!wrapper) return;
            const controls = wrapper.getElementsByClassName('controls');
            if (!controls) return;
            const html  = htmls[repId];
            const level = levels[repId];
            const regex = new RegExp('\{index-' + level + '\}',"g");
            let   index = indexes[repId];
            controls[0].innerHTML += html.replace(regex, index++);
            indexes[repId] = index;
            _repRemoveHandlers();
         }.bind(el));
      }
   };
   const repeatable = function(htmls, indexes, levels) {
      WCom.Util.Event.onReady(function(event) {
         _repAddHandlers(htmls, indexes, levels);
         _repRemoveHandlers();
      });
   };
   const revealPassword = function(id) {
      const field = document.getElementById(id);
      const handler = function(event) { field.type = 'password' };
      field.addEventListener('mouseleave', handler);
      field.type = 'text';
   };
   const scan = function(content = document, options = {}) {
      if (WCom.Form.Renderer.scan(content, options)) return;
      const forms = content.getElementsByTagName('form');
      if (!forms) return;
      const formClass = options.formClass ? options.formClass : defaultFormClass;
      for (const form of forms) {
         if (!form.classList.contains(formClass)) continue;
         WCom.Form.DataStructure.manager.scan(form);
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
   const showIfRequired = function(valueFieldName, toggleFieldNames, url) {
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
      for (const el of parent.querySelectorAll('.alert-error')) {
         parent.removeChild(el);
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
   WCom.Util.Event.onReady(function(event) { scan() });
   return {
      fieldChange: fieldChange,
      focusFirst: focusFirst,
      repeatable: repeatable,
      revealPassword: revealPassword,
      scan: scan,
      showIfRequired: showIfRequired,
      unrequire: unrequire,
      updateDigits: updateDigits,
      updateTimeWithZone: updateTimeWithZone,
      validateField: validateField,
      wrapperIdPrefix: wrapperIdPrefix
   };
})();
