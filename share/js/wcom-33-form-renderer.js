// Package WCom.Form.Renderer
// Dependencies WCom.Util WCom.Form.Util
WCom.Form.Renderer = (function() {
   const dsName = 'formConfig';
   const triggerClass = 'html-forms';
   // Form
   class HTMLForm {
      // Public
      constructor(container) {
         this.container = container;
         const data = container.dataset[dsName];
         if (!data) return;
         this.config = JSON.parse(data);
      }
      render() {
         const config = this.config;
         const attr = config.attributes;
         this.form = this.h.form({
            acceptCharset: attr['accept-charset'],
            action: attr.action,
            className: attr.className,
            enctype: attr.enctype,
            id: attr.id,
            method: attr.method,
            name: config.name
         });
         if (attr.novalidate == 'novalidate')
            this.form.setAttribute('novalidate', 'novalidate');
         if (config.msgsBeforeStart) this._renderFormMessages(this.container);
         const wrapper = this._createFormWrapper();
         if (!config.msgsBeforeStart) this._renderFormMessages(wrapper);
         if (config.infoMessage) this._renderFormInformation(wrapper);
         for (const field of config.fields) this._renderField(wrapper, field);
         this.animateButtons(this.form, '.input-field button');
         WCom.Form.Util.focusFirst(this.form);
      }
      // Private
      _createFormWrapper() {
         const config = this.config;
         if (!config.doFormWrapper) {
            this.container.appendChild(this.form);
            return this.form;
         }
         const wrapper = this.h[config.wrapperTag](config.wrapperAttr);
         const legendAttr = { className: 'form-title' };
         if (config.wrapperTag != 'fieldset') {
            this.container.appendChild(wrapper);
            if (config.legend) {
               const legend = this.h.div(legendAttr, config.legend);
               wrapper.appendChild(legend);
            }
            wrapper.appendChild(this.form);
            return this.form;
         }
         this.container.appendChild(this.form);
         if (config.legend) {
            const legend = this.h.legend(legendAttr, config.legend);
            wrapper.appendChild(legend);
         }
         this.form.appendChild(wrapper);
         return wrapper;
      }
      _renderField(container, field) {
         const wrapper = this.h.div(field.wrapperAttr);
         if (field.doLabel && field.label && !field.labelRight) {
            const label = this.h[field.labelTag](field.labelAttr, field.label);
            wrapper.appendChild(label);
         }
         const className = 'HTMLField' + field.widget;
         const fieldWidget = eval('new ' + className + '(field)');
         const element = fieldWidget.render(wrapper);
         if (field.depends)
            element.setAttribute('data-field-depends', field.depends);
         if (field.disabled)
            element.setAttribute('disabled', 'disabled');
         if (field.toggle)
            element.setAttribute('data-toggle-config', field.toggle);
         if (field.doLabel && field.label && field.labelRight) {
            const label = this.h[field.labelTag](field.labelAttr, field.label);
            wrapper.appendChild(label);
         }
         this._renderFieldErrors(wrapper, field, element);
         container.appendChild(wrapper);
      }
      _renderFieldErrors(container, field, element) {
         const errorAttr = { className: 'alert alert-error' };
         for (const error of field.result.allErrors) {
            container.appendChild(this.h.span(errorAttr, error));
            element.removeAttribute('disabled');
         }
         const warningAttr = { className: 'alert alert-warning' };
         for (const warning of field.result.allWarnings) {
            container.appendChild(this.h.span(warningAttr, error));
            element.removeAttribute('disabled');
         }
         if (field.info) {
            const infoAttr = { className: 'alert alert-info' };
            container.appendChild(this.h.div(infoAttr, field.info));
         }
      }
      _renderFormInformation(container) {
         const config = this.config;
         if (!config.infoMessage) return;
         const infoAttr = { className: 'alert alert-info' };
         container.appendChild(this.h.div(infoAttr, config.infoMessage));
      }
      _renderFormMessages(container) {
         const config = this.config;
         const wrapper = this.h.div({ className: 'form-messages' });
         if (config.errorMsg) {
            const errorAttr = { className: 'alert alert-severe' };
            wrapper.appendChild(this.h.div(errorAttr, config.errorMsg));
         }
         else if (config.successMsg) {
            const successAttr = { className: 'alert alert-success' };
            wrapper.appendChild(this.h.div(successAttr, config.successMsg));
         }
         container.appendChild(wrapper);
      }
   }
   Object.assign(HTMLForm.prototype, WCom.Util.Markup);
   // Field baseclass
   class HTMLField {
      constructor(field) {
         this.field = field;
         this.attr = {
            ...field.attributes,
            id: field.id,
            name: field.htmlName || field.name
         };
         if (field.handlers) this._handlers();
         if (field.htmlElement == 'input') this.attr.type = field.inputType;
         if (field.value !== undefined) this.attr.value = field.value;
      }
      _handlers() {
         for (const [ev, handler] of Object.entries(this.field.handlers)) {
            this.attr[ev] = function(event) { eval(handler) };
         }
      }
   }
   Object.assign(HTMLField.prototype, WCom.Util.Markup);
   // Field subclasses
   class HTMLFieldButton extends HTMLField {
      render(wrapper) {
         const field = this.field;
         const element = this.h[field.htmlElement](this.attr);
         if (field.displayAs) element.appendChild(this.h.span(field.displayAs));
         wrapper.appendChild(element);
         return element;
      }
   }
   class HTMLFieldCheckbox extends HTMLField {
      render(wrapper) {
         const field = this.field;
         const element = this.h.span({ className: 'checkbox-wrapper' });
         this.attr.type = field.inputType;
         this.attr.value = field.checkboxValue;
         if (field.fif == field.checkboxValue) this.attr.checked = 'checked';
         element.appendChild(this.h.input(this.attr));
         wrapper.appendChild(element);
         return element;
      }
   }
   class HTMLFieldDataStructure extends HTMLField {
      render(wrapper) {
         const field = this.field;
         const attr = { className: 'data-structure input-field' };
         const element = this.h.div(attr);
         this.attr.type = this.field.inputType;
         const hidden = this.h.input(this.attr);
         hidden.setAttribute('data-ds-specification', field.dsSpec);
         element.appendChild(hidden);
         wrapper.appendChild(element);
         WCom.Form.DataStructure.manager.scan(wrapper);
         return element;
      }
   }
   class HTMLFieldDigits extends HTMLField {
      render(wrapper) {
         const field = this.field;
         const digits = [];
         let count = 0;
         while (count < field.size) {
            digits.push(this._createDigit(count));
            count += 1;
         }
         const wrapperAttr = { className: 'digit-input-wrapper' };
         wrapper.appendChild(this.h.span(wrapperAttr, digits));
         const hiddenAttr = {
            id: field.id,
            name: field.htmlName || field.name,
            required: (this.attr.required == 'required' ? true : false)
         };
         const element = this.h.hidden(hiddenAttr);
         wrapper.appendChild(element);
         return element;
      }
      _createDigit(count) {
         const field = this.field;
         const id = field.id + '-' + count;
         return this.h.input({
            ...field.attributes,
            className: 'digit',
            id: id,
            name: id,
            oninput: this._handler(field.id, count),
            size: 1,
            type: field.inputType,
            value: ''
         });
      }
      _handler(id, count) {
         return function(event) { WCom.Form.Util.updateDigits(id, count) }
      }
   }
   class HTMLFieldImage extends HTMLField {
      render(wrapper) {
         const field = this.field;
         const attr = { ...field.attributes, id: field.id, src: field.src };
         const element = this.h.img(attr);
         wrapper.appendChild(element);
         return element;
      }
   }
   class HTMLFieldLink extends HTMLField {
      render(wrapper) {
         const field = this.field;
         const attr = { ...field.attributes, href: field.href, id: field.id };
         const element = this.h.a(attr, field.displayAs);
         wrapper.appendChild(element);
         return element;
      }
   }
   class HTMLFieldNoValue extends HTMLField {
      render(wrapper) {
         const element = this.h.span();
         element.innerHTML = this.field.html;
         wrapper.appendChild(element);
         return element;
      }
   }
   class HTMLFieldSelect extends HTMLField {
      render(wrapper) {
         const field = this.field;
         if (field.multiple) {
            this.attr.multiple = 'multiple';
            this.attr.size = field.size;
         }
         const element = this.h[field.htmlElement](this.attr);
         let nextOptionId = 0;
         if (field.emptySelect) {
            const attr = { id: field.id + '-' + nextOptionId, value: '' };
            element.appendChild(this.h.option(attr, field.emptySelect));
            nextOptionId++;
         }
         for (const option of field.options) {
            if (option.group) {
               const optgroup = this.h.optgroup({ label: option.group });
               for (const group of option.options) {
                  optgroup.appendChild(this._renderOption(group, nextOptionId));
                  nextOptionId++;
               }
               element.appenChild(optgroup);
            }
            else {
               element.appendChild(this._renderOption(option, nextOptionId));
               nextOptionId++;
            }
         }
         wrapper.appendChild(element);
         return element;
      }
      _renderOption(option, nextOptionId) {
         const field = this.field;
         const attr = {
            id: field.id + '-' + nextOptionId,
            value: option.value
         };
         if (option.disabled) attr.disabled = 'disabled';
         if (this.h.typeOf(field.fif) == 'array') {
            for (const selectedVal of field.fif) {
               if (selectedVal == option.value) attr.selected = 'selected';
            }
         }
         else {
            if (field.fif == option.value) attr.selected = 'selected';
         }
         return this.h.option(attr, option.label);
      }
   }
   class HTMLFieldSelector extends HTMLField {
      render(wrapper) {
         const field = this.field;
         this.attr.value = field.fif;
         const handler = field.clickHandler; delete field.clickHandler;
         const element = this.h.input(this.attr);
         element.setAttribute('readonly', 'readonly');
         wrapper.appendChild(element);
         const attr = {
            id: field.id + '_select',
            name: field.htmlName + '_select',
            onclick: function(event) { eval(handler) },
            type: 'submit',
            value: ''
         };
         const button = this.h.button(attr, this.h.span(field.displayAs));
         wrapper.appendChild(button);
         return element;
      }
   }
   class HTMLFieldSpan extends HTMLField {
      render(wrapper) {
         const attr = { ...this.field.attributes, id: this.field.id };
         const element = this.h.span(attr, this.field.value);
         wrapper.appendChild(element);
         return element;
      }
   }
   class HTMLFieldText extends HTMLField {
      render(wrapper) {
         this.attr.value = this.field.fif;
         const element = this.h[this.field.htmlElement](this.attr);
         wrapper.appendChild(element);
         return element;
      }
   }
   class HTMLFieldHidden extends HTMLFieldText {
   }
   class HTMLFieldPassword extends HTMLFieldText {
      render(wrapper) {
         const element = super.render(wrapper);
         if (this.field.reveal) {
            const id = this.field.id;
            const handler = function(event) {
               WCom.Form.Util.revealPassword(id);
            };
            const attr = { className: 'reveal', onmouseover: handler };
            wrapper.appendChild(this.h.span(attr, '👁'));
         }
         return element;
      }
   }
   class HTMLFieldTextarea extends HTMLField {
      render(wrapper) {
         this.attr.cols = this.field.cols;
         this.attr.rows = this.field.rows;
         const element = this.h.textarea(this.attr, this.field.fif);
         wrapper.appendChild(element);
         return element;
      }
   }
   class HTMLFieldUpload extends HTMLField {
      render(wrapper) {
         this.attr.type = 'file';
         const element = this.h.input(this.attr);
         wrapper.appendChild(element);
         return element;
      }
   }
   // Exports
   return {
      scan: function(content, options) {
         const els = content.getElementsByClassName(triggerClass);
         if (!els) return false;
         for (const el of els) {
            const form = new HTMLForm(el);
            form.render();
         }
         return true;
      }
   };
})();
