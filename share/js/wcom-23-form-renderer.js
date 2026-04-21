/** @file HTML Forms - Renderer
    @classdesc Renders forms
    @author pjfl@cpan.org (Peter Flanigan)
    @version 0.2.20
*/
WCom.Form.Renderer = (function() {
   const dsName = 'formConfig';
   const triggerClass = 'html-forms';
   /** @class
       @classdesc Form class
       @alias Form/HTMLForm
   */
   class HTMLForm {
      // Public
      /** @constructs
          @desc Creates the form object
          @param {element} container Container element for the form
          @param {object} config
          @property {object} config.attributes The form element attributes
          @property {integer} config.currentPage
          @property {array} config.fieldGroups Defines groups of fields
          @property {array} config.fields Each object in the array defines a
             field on the form
          @property {boolean} config.hasPageBreaks
          @property {boolean} config.msgsBeforeStart
          @property {string} config.novalidate If set to 'novalidate' it is
             applied to the form
          @property {integer} config.pageSize
          @property {number} config.titleWait How long to wait in seconds before
             the mouseover tips appear. Defaults to 0.85
      */
      constructor(container, config) {
         this.container = container;
         this.config = config;
         this.fieldGroups = config.fieldGroups;
         this.titleWait =  config.titleWait || 0.85;
         this.fieldIndex = {};
         for (const field of config.fields) {
            this.fieldIndex[field.name] = field;
         }
      }
      /** @function
          @desc Render the form
       */
      render() {
         const config = this.config;
         if (!config) return;
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
         if (config.msgsBeforeStart) this._formMessages(this.container);
         const wrapper = this._formWrapper();
         const pageSize = config.pageSize;
         const hasPages = pageSize > 0 || config.hasPageBreaks ? true : false;
         if (hasPages) {
            this.pages = [];
            this.pageItems = [];
            this.pageItemSelected = 0;
            this.pageList = this.h.ul({ className: 'page-list' });
            wrapper.appendChild(this.pageList);
         }
         let fieldCount = 0;
         let pageCount = 0;
         let page = wrapper;
         for (const field of config.fields) {
            if (field.fieldGroup) continue;
            if (field.pageBreak) fieldCount = 0;
            if (fieldCount == 0) {
               if (hasPages) {
                  if (!this.pageWrapper) {
                     this.pageWrapper = this.h.div({ className:'page-wrapper'});
                     wrapper.appendChild(this.pageWrapper);
                  }
                  page = this._page(this.pageWrapper, pageCount++);
               }
               else this._formInformation(page, pageCount);
            }
            this._field(page, field);
            fieldCount += 1;
            if (pageSize > 0 && fieldCount >= pageSize) fieldCount = 0;
         }
         WCom.Form.Toggle.scan(this.form);
         const btnSelect = '.input-field button, .input-field a.form-button';
         this.animateButtons(this.form, btnSelect);
         if (hasPages) {
            this._selectPage(config.currentPage);
            WCom.Form.Util.focusFirst(this.pages[this.pageItemSelected]);
         }
         else WCom.Form.Util.focusFirst(this.form);
      }
      // Private
      _field(container, field) {
         const className = 'HTMLField' + field.widget;
         const widget = eval('new ' + className + '(this, field)');
         widget.renderField(container);
      }
      _formInformation(container, index) {
         const config = this.config;
         if (!config.infoMessage) return;
         const className = config.tags.infoClass || 'alert alert-info';
         let message = config.infoMessage;
         if (this.h.typeOf(config.infoMessage) == 'array') {
            message = config.infoMessage[index];
         }
         container.appendChild(this.h.div({ className }, message));
         if (!config.msgsBeforeStart) this._formMessages(container);
      }
      _formMessages(container) {
         const config = this.config;
         if (config.tags.noFormMessages) return;
         let className = config.tags.messagesWrapperClass || 'form-messages';
         const wrapper = this.h.div({ className });
         if (config.errorMsg) {
            className = config.tags.errorClass || 'alert alert-error-message';
            wrapper.appendChild(this.h.span({ className }, config.errorMsg));
         }
         else if (config.successMsg) {
            className = config.tags.successClass
               || 'alert alert-success-message';
            wrapper.appendChild(this.h.span({ className }, config.successMsg));
         }
         if (config.errors.length) {
            className = config.tags.errorClass || 'alert alert-error';
            wrapper.appendChild(this.h.span({ className }, config.errors));
         }
         container.appendChild(wrapper);
      }
      _formWrapper() {
         const config = this.config;
         if (!config.doFormWrapper) {
            if (config.wrapperAttr) {
               for (const className of config.wrapperAttr.className.split(/ /)){
                  this.form.classList.add(className);
               }
            }
            this.container.appendChild(this.form);
            return this.form;
         }
         const wrapperTag = config.tags.wrapperTag || 'fieldset';
         const wrapper = this.h[wrapperTag](config.wrapperAttr);
         if (wrapperTag == 'fieldset') {
            this.container.appendChild(this.form);
            if (config.tags.legend) this._legend(wrapper, 'legend');
            this.form.appendChild(wrapper);
            return wrapper;
         }
         this.container.appendChild(wrapper);
         if (config.tags.legend) this._legend(wrapper, 'div');
         wrapper.appendChild(this.form);
         return this.form;
      }
      _legend(wrapper, tag) {
         const legendAttr = { className: 'form-title' };
         const legend = this.h[tag](legendAttr, this.config.tags.legend);
         wrapper.appendChild(legend);
      }
      _page(wrapper, count) {
         const attr = {
            onclick: function(event) { this._selectPage(count) }.bind(this)
         };
         const pageName = this.config.pageNames[count];
         const label = pageName ? pageName : 'Page ' + (count + 1);
         this.pageItems[count] = this.h.li(attr, label);
         if (count == this.pageItemSelected)
            this.pageItems[count].classList.add('selected');
         this.pageList.appendChild(this.pageItems[count]);
         this.pages[count] = this.h.div({ className: 'form-page' });
         if (count != this.pageItemSelected)
            this.pages[count].classList.add('hide');
         wrapper.appendChild(this.pages[count]);
         this._formInformation(this.pages[count], count);
         return this.pages[count];
      }
      _selectPage(count) {
         const changed = this.pageItemSelected == count ? false : true;
         if (this.pageItems[this.pageItemSelected])
            this.pageItems[this.pageItemSelected].classList.remove('selected');
         const oldPage = this.pages[this.pageItemSelected];
         if (changed && oldPage) oldPage.classList.add('fade');
         this.pageItemSelected = count;
         this.pageItems[this.pageItemSelected].classList.add('selected');
         this.pages[this.pageItemSelected].classList.remove('hide');
         setTimeout(function() {
            if (changed && oldPage) {
               oldPage.classList.add('hide');
               oldPage.classList.remove('fade');
            }
         }.bind(this), (1000 * 0.5));
      }
   }
   Object.assign(HTMLForm.prototype, WCom.Util.Markup);
   /** @class
       @classdesc Field base class
       @alias Form/HTMLField
   */
   class HTMLField {
      /** @constructs
          @desc Creates the field object
          @param {object} form The parent form object
          @param {object} field Configuration attributes for the field
      */
      constructor(form, field) {
         this.form = form;
         this.field = field;
         if (WCom.Navigation.feature('tooltips')) {
            this.title = field.attributes.title; delete field.attributes.title;
         }
         this.attr = {
            ...field.attributes,
            id: field.id,
            name: field.htmlName || field.name,
         };
         if (field.handlers) this._setHandlers(this.attr, field.handlers);
         if (field.htmlElement == 'input') {
            this.attr.autocomplete = field.autocomplete ? 'on' : 'off';
            this.attr.type = field.inputType;
         }
         if (field.value !== undefined) this.attr.value = field.value;
      }
      /** @function
          @desc Render a field
          @param {element} container Containing element for the field
      */
      renderField(container) {
         const field = this.field;
         const wrapper = this.h.div(field.wrapperAttr);
         if (field.infoTop) this._fieldInfo(wrapper, field);
         if (field.doLabel && field.label.length && !field.labelRight) {
            this._fieldLabel(wrapper, field);
         }
         const element = this.render(wrapper);
         if (element) this._setElementAttributes(field, element);
         if (field.doLabel && field.label.length && field.labelRight) {
            this._fieldLabel(wrapper, field);
         }
         if (element) {
            if (this.title) this._fieldTitle(wrapper, field);
            this._fieldAlerts(wrapper, field, element);
            if (!field.infoTop) this._fieldInfo(wrapper, field);
         }
         if (field.doLabel) {
            if (field.labelTag == 'span') wrapper.classList.add('floating');
            else wrapper.classList.add('fixed');
         }
         container.appendChild(wrapper);
      }
      _fieldAlerts(container, field, element) {
         const wrapper = this.h.div({ className: 'alert' });
         const errorAttr = { className: 'alert-error' };
         let found = false;
         for (const error of field.result.allErrors) {
            wrapper.appendChild(this.h.span(errorAttr, error));
            element.removeAttribute('disabled');
            found = true;
         }
         const warningAttr = { className: 'alert-warning' };
         for (const warning of field.result.allWarnings) {
            wrapper.appendChild(this.h.span(warningAttr, error));
            element.removeAttribute('disabled');
            found = true;
         }
         if (found) container.appendChild(wrapper);
      }
      _fieldInfo(container, field) {
         if (field.info && !field.hideInfo) {
            const infoAttr = { className: 'alert alert-info' };
            const info = this.h.div(infoAttr, field.info);
            if (field.infoTop) info.classList.add('top');
            container.appendChild(info);
         }
      }
      _fieldLabel(wrapper, field) {
         if (field.widget == 'NoRender') return;
         const attr = field.labelAttr;
         if (attr.className.match(/\-multiple/)
             || field.widget == 'DataStructure') {
            delete attr.htmlFor;
         }
         return wrapper.appendChild(this.h[field.labelTag](attr, field.label));
      }
      _fieldTitle(container, field) {
         const id = 'tooltip-' + field.name;
         const attr = { className: 'tooltip hide', id };
         const tooltip = this.h.div(attr, this.h.frag(this.title));
         const wait = this.form.titleWait;
         let timeoutId;
         container.addEventListener('mouseover', () => {
            timeoutId = setTimeout(function() {
               tooltip.classList.remove('hide');
            }, 1000 * wait);
         });
         container.addEventListener('mouseout', () => {
            if (timeoutId) clearTimeout(timeoutId);
            tooltip.classList.add('hide');
         });
         container.appendChild(tooltip);
      }
      _setElementAttributes(field, element) {
         if (field.depends)
            element.setAttribute('data-field-depends', field.depends);
         if (field.disabled) element.setAttribute('disabled', 'disabled');
         if (field.noSpellCheck) element.setAttribute('spellcheck', 'false');
         if (field.toggle) {
            element.setAttribute('data-toggle-config', field.toggle);
            const event = JSON.parse(field.toggle).event;
            element.addEventListener(event, function() {
               WCom.Form.Toggle.toggleFields(element.name);
            }.bind(this));
         }
      }
      _setHandlers(acc, handlers) {
         for (const [ev, handler] of Object.entries(handlers)) {
            if (handler) acc[ev] = this.getEventHandler(handler);
            else acc[ev] = function(event) { event.preventDefault() };
         }
      }
   }
   Object.assign(HTMLField.prototype, WCom.Util.Markup);
   Object.assign(HTMLField.prototype, WCom.Util.Modifiers);
   /** @class
       @classdesc Renders a button
       @extends Form/HTMLField
       @alias Form/HTMLFieldButton
   */
   class HTMLFieldButton extends HTMLField {
      /** @function
          @desc Render a button
          @param {element} wrapper Container for the button element
          @return {element} Returns the button
      */
      render(wrapper) {
         const field = this.field;
         const element = this.h[field.htmlElement](this.attr);
         if (field.displayAs) {
            let displayAs;
            if (field.icons)
               displayAs = this.h.icon(JSON.parse(field.displayAs));
            else displayAs = this.h.span(field.displayAs);
            element.appendChild(displayAs);
         }
         wrapper.appendChild(element);
         return element;
      }
   }
   /** @class
       @classdesc Renders a checkbox
       @extends Form/HTMLField
       @alias Form/HTMLFieldCheckbox
   */
   class HTMLFieldCheckbox extends HTMLField {
      /** @function
          @desc Render a checkbox
          @param {element} wrapper Container for the checkbox element
          @return {element} Returns the checkbox
      */
      render(wrapper) {
         const field = this.field;
         this.attr.type = field.inputType;
         this.attr.value = field.checkboxValue;
         if (field.fif == field.checkboxValue) this.attr.checked = 'checked';
         const element = this.h.input(this.attr);
         const boxwrap = this.h.span({ className: 'checkbox-wrapper' });
         boxwrap.appendChild(element);
         wrapper.appendChild(boxwrap);
         return element;
      }
   }
   /** @class
       @classdesc Renders a checkbox group
       @extends Form/HTMLField
       @alias Form/HTMLFieldCheckboxGroup
   */
   class HTMLFieldCheckboxGroup extends HTMLField {
      /** @function
          @desc Render a checkbox group
          @param {element} wrapper Container for the checkbox group element
          @return {element} Returns the checkbox group (an unordered list)
      */
      render(wrapper) {
         const element = this.h.ul({ className: 'checkbox-group' });
         const field = this.field;
         let nextOptionId = 0;
         for (const option of field.options) {
            element.appendChild(this._renderOption(option, nextOptionId));
            nextOptionId++;
         }
         wrapper.appendChild(element);
         return element;
      }
      _renderOption(option, nextOptionId) {
         const field = this.field;
         const itemAttr = {};
         if (this.h.typeOf(field.fif) == 'array') {
            for (const selectedVal of field.fif) {
               if (selectedVal == option.value) itemAttr.selected = 'selected';
            }
         }
         else {
            if (field.fif == option.value) itemAttr.selected = 'selected';
         }
         const id = field.id + '-' + nextOptionId;
         const boxAttr = { id, name: field.name, value: option.value };
         if (itemAttr.selected) boxAttr.checked = 'checked';
         const checkbox = this.h.checkbox(boxAttr);
         const wrapperAttr = { className: 'checkbox-wrapper' };
         const wrapper = this.h.span(wrapperAttr, checkbox);
         const labelAttr = { className: 'checkbox-label', htmlFor: id };
         const label = this.h.label(labelAttr, option.label);
         return this.h.li(itemAttr, [label, wrapper]);
      }
   }
   /** @class
       @classdesc Renders a colour selector
       @extends Form/HTMLField
       @alias Form/HTMLFieldColour
   */
   class HTMLFieldColour extends HTMLField {
      /** @function
          @desc Render a colour selector
          @param {element} wrapper Container for the colour selector element
          @return {element} Returns the colour selector element
      */
      render(wrapper) {
         this.attr.list = 'custom-colours';
         this.attr.colorspace = 'oklch';
         const element = this.h.colour(this.attr);
         wrapper.appendChild(element);
         const options = [];
         for (const option of this.field.options) {
            options.push(this.h.option({ value: option.value }));
         }
         const list = this.h.datalist({ id: 'custom-colours' }, options);
         wrapper.appendChild(list);
         return element;
      }
   }
   /** @class
       @classdesc Renders a list of fields
       @extends Form/HTMLField
       @alias Form/HTMLFieldCompound
   */
   class HTMLFieldCompound extends HTMLField {
      /** @function
          @desc Render a compound field. One containing other fields
          @param {element} wrapper Container for the compound element
      */
      render(wrapper) {
         for (const field of this.field.sortedFields) {
            const className = 'HTMLField' + field.widget;
            const widget = eval('new ' + className + '(this, field)');
            widget.renderField(wrapper);
         }
         this._fieldTitle(wrapper, this.field);
      }
   }
   /** @class
       @classdesc Renders a data structure
       @extends Form/HTMLField
       @alias Form/HTMLFieldDataStructure
   */
   class HTMLFieldDataStructure extends HTMLField {
      /** @function
          @desc Render a data structure. One containing rows/columns of
             other fields
          @param {element} wrapper Container for the data structure element
          @return {element} Returns the data structure element
      */
      render(wrapper) {
         const field = this.field;
         const attr = { className: 'data-structure input-field' };
         const element = this.h.div(attr);
         this.attr.type = this.field.inputType;
         const hidden = this.h.input(this.attr);
         hidden.setAttribute('data-ds-specification', field.dsSpec);
         element.appendChild(hidden);
         wrapper.appendChild(element);
         WCom.Form.DataStructure.scan(wrapper);
         return element;
      }
   }
   /** @class
       @classdesc Renders a list of digits
       @extends Form/HTMLField
       @alias Form/HTMLFieldDigits
   */
   class HTMLFieldDigits extends HTMLField {
      /** @function
          @desc Render a group of digit fields
          @param {element} wrapper Container for the input digit fields
          @return {element} Returns the hidden element which will contain
             the fields value
      */
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
            inputmode: 'numeric',
            oninput: this._handler(field.id, count),
            pattern: '[0-9]',
            required: (this.attr.required == 'required' ? true : false),
            size: 1,
            type: field.inputType,
            value: ''
         });
      }
      _handler(id, count) {
         return function(event) { WCom.Form.Util.updateDigits(id, count) }
      }
   }
   /** @class
       @classdesc Renders a field group
       @extends Form/HTMLField
       @alias Form/HTMLFieldGroup
   */
   class HTMLFieldGroup extends HTMLField {
      /** @function
          @desc Render a group fields
          @param {element} wrapper Container for the field group
      */
      render(wrapper) {
         const form = this.form;
         const fields = form.fieldGroups[this.field.name];
         if (!fields) return;
         if (this.field.info && !this.field.hideInfo) {
            const infoAttr = { className: 'alert alert-info' };
            wrapper.appendChild(this.h.div(infoAttr, this.field.info));
         }
         for (const field_name of fields) {
            const field = form.fieldIndex[field_name];
            if (!field) continue;
            const className = 'HTMLField' + field.widget;
            const widget = eval('new ' + className + '(form, field)');
            widget.renderField(wrapper);
         }
         return;
      }
   }
   /** @class
       @classdesc Renders an image
       @extends Form/HTMLField
       @alias Form/HTMLFieldImage
   */
   class HTMLFieldImage extends HTMLField {
      /** @function
          @desc Render an image
          @param {element} wrapper Container for the image
          @return {element} Returns the image element
      */
      render(wrapper) {
         const field = this.field;
         const attr = { ...field.attributes, id: field.id, src: field.src };
         const element = this.h.img(attr);
         wrapper.appendChild(element);
         return element;
      }
   }
   /** @class
       @classdesc Renders a link
       @extends Form/HTMLField
       @alias Form/HTMLFieldLink
   */
   class HTMLFieldLink extends HTMLField {
      /** @function
          @desc Render a link
          @param {element} wrapper Container for the link
          @return {element} Returns the link element
      */
      render(wrapper) {
         const field = this.field;
         const attr = { ...field.attributes, href: field.href, id: field.id };
         delete attr.title;
         const element = this.h.a(attr, this.h.span({}, field.displayAs));
         wrapper.appendChild(element);
         return element;
      }
   }
   /** @class
       @classdesc Renders nothing
       @extends Form/HTMLField
       @alias Form/HTMLFieldNoRender
   */
   class HTMLFieldNoRender extends HTMLField {
      /** @function
          @desc Renders nothing
          @param {element} wrapper Container for the nothing
      */
      render(wrapper) {
         return;
      }
   }
   /** @class
       @classdesc Renders a fragment of HTML
       @extends Form/HTMLField
       @alias Form/HTMLFieldNoValue
   */
   class HTMLFieldNoValue extends HTMLField {
      /** @function
          @desc Render a fragment of raw HTML
          @param {element} wrapper Container for the fragment
      */
      render(wrapper) {
         wrapper.appendChild(this.h.frag(this.field.html));
         return;
      }
   }
   /** @class
       @classdesc Renders a checkbox group
       @extends Form/HTMLField
       @alias Form/HTMLFieldRadioGroup
   */
   class HTMLFieldRadioGroup extends HTMLField {
      /** @function
          @desc Render an unordered list of radio buttons
          @param {element} wrapper Container for the list
          @return {element} Returns the list element
      */
      render(wrapper) {
         const element = this.h.ul({ className: 'radio-group' });
         const field = this.field;
         let nextOptionId = 0;
         for (const option of field.options) {
            element.appendChild(this._renderOption(option, nextOptionId));
            nextOptionId++;
         }
         wrapper.appendChild(element);
         return element;
      }
      _renderOption(option, nextOptionId) {
         const field = this.field;
         const itemAttr = {};
         if (this.h.typeOf(field.fif) == 'array') {
            for (const selectedVal of field.fif) {
               if (selectedVal == option.value) itemAttr.selected = 'selected';
            }
         }
         else {
            if (field.fif == option.value) itemAttr.selected = 'selected';
         }
         const id = field.id + '-' + nextOptionId;
         const buttonAttr = { id, name: field.name, value: option.value };
         if (itemAttr.selected) buttonAttr.checked = 'checked';
         const button = this.h.radio(buttonAttr);
         const wrapperAttr = { className: 'button-wrapper' };
         const wrapper = this.h.span(wrapperAttr, button);
         const labelAttr = { className: 'button-label', htmlFor: id };
         const label = this.h.label(labelAttr, option.label);
         return this.h.li(itemAttr, [label, wrapper]);
      }
   }
   /** @class
       @classdesc Renders a select/options field
       @extends Form/HTMLField
       @alias Form/HTMLFieldSelect
   */
   class HTMLFieldSelect extends HTMLField {
      /** @function
          @desc Render a select/option field. If field multiple is true
              allow multiple selections, displaying field size elements
          @param {element} wrapper Container for the select element
          @return {element} Returns the select element
      */
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
   /** @class
       @classdesc Renders a selector for many values
       @extends Form/HTMLField
       @alias Form/HTMLFieldSelectMany
   */
   class HTMLFieldSelectMany extends HTMLField {
      /** @function
          @desc Render a select many from many element
          @param {element} wrapper Container for the select element
          @return {element} Returns the select element
      */
      render(wrapper) {
         const field = this.field;
         const handler = field.clickHandler; delete field.clickHandler;
         const title = this.attr.title; delete this.attr.title;
         const element = this._renderList(wrapper);
         const attr = {
            id: field.id + '_select',
            name: field.htmlName + '_select',
            type: 'submit',
            value: ''
         };
         this._setHandlers(attr, { onclick: handler });
         let displayAs;
         if (field.htmlElement == 'icon') {
            displayAs = this.h.icon(JSON.parse(field.displayAs));
         }
         else { displayAs = this.h.span(field.displayAs) }
         wrapper.appendChild(this.h.button(attr, displayAs));
         return element;
      }
      _renderList(wrapper) {
         const field = this.field;
         const fieldId = '_' + field.id + '-group';
         const listAttr = { className: 'selectmany-group', id: fieldId };
         const element = this.h.ul(listAttr);
         if (field.size) {
            const height = (10 + (20 * field.size)) + 'px';
            element.style['max-height'] = height;
         }
         let nextOptionId = 0;
         let value = '';
         for (const option of field.options) {
            const item = this._renderItem(option, nextOptionId);
            if (item) {
               element.appendChild(item);
               value = value + (value ? ',' : '') + option.value;
               nextOptionId++;
            }
         }
         const id = '_' + field.id;
         wrapper.appendChild(this.h.hidden({ id, name: id, value }));
         wrapper.appendChild(element);
         return element;
      }
      _renderItem(option, nextOptionId) {
         const field = this.field;
         let selected = false;
         if (this.h.typeOf(field.fif) == 'array') {
            for (const selectedVal of field.fif) {
               if (selectedVal == option.value) selected = true;
            }
         }
         else {
            if (field.fif == option.value) selected = true;
         }
         if (!selected) return;
         const id = '_' + field.id + '-' + nextOptionId;
         const labelAttr = { className: 'item-label' };
         const label = this.h.label(labelAttr, option.label);
         const hiddenAttr = { id, name: field.id, value: option.value};
         return this.h.li({}, [label, this.h.hidden(hiddenAttr)]);
      }
   }
   /** @class
       @classdesc Renders a selector for one value
       @extends Form/HTMLField
       @alias Form/HTMLFieldSelectOne
   */
   class HTMLFieldSelectOne extends HTMLField {
      /** @function
          @desc Render a select one from many
          @param {element} wrapper Container for the select element
          @return {element} Returns the select element
      */
      render(wrapper) {
         const field = this.field;
         this.attr.value = field.fif;
         const handler = field.clickHandler; delete field.clickHandler;
         const title = this.attr.title; delete this.attr.title;
         const element = this.h[field.htmlElement](this.attr);
         element.setAttribute('readonly', 'readonly');
         wrapper.appendChild(element);
         const attr = {
            id: field.id + '_select',
            name: field.htmlName + '_select',
            type: 'submit',
            value: ''
         };
         this._setHandlers(attr, { onclick: handler });
         let displayAs;
         if (field.htmlElement == 'icon') {
            displayAs = this.h.icon(JSON.parse(field.displayAs));
         }
         else { displayAs = this.h.span(field.displayAs) }
         wrapper.appendChild(this.h.button(attr, displayAs));
         return element;
      }
   }
   /** @class
       @classdesc Renders a span
       @extends Form/HTMLField
       @alias Form/HTMLFieldSpan
   */
   class HTMLFieldSpan extends HTMLField {
      /** @function
          @desc Render a span element
          @param {element} wrapper Container for the span element
          @return {element} Returns the span element
      */
      render(wrapper) {
         const attr = { ...this.field.attributes, id: this.field.id };
         const element = this.h.span(attr, this.field.value);
         wrapper.appendChild(element);
         return element;
      }
   }
   /** @class
       @classdesc Renders a text field
       @extends Form/HTMLField
       @alias Form/HTMLFieldText
   */
   class HTMLFieldText extends HTMLField {
      /** @function
          @desc Render a span text input field
          @param {element} wrapper Container for the input element
          @return {element} Returns the input element
      */
      render(wrapper) {
         this.attr.value = this.field.fif;
         const element = this.h[this.field.htmlElement](this.attr);
         wrapper.appendChild(element);
         return element;
      }
   }
   /** @class
       @classdesc Renders a captcha
       @extends Form/HTMLFieldText
       @alias Form/HTMLFieldCaptcha
   */
   class HTMLFieldCaptcha extends HTMLFieldText {
      /** @function
          @desc Render a Captcha field
          @param {element} wrapper Container for the captcha element
      */
      render(wrapper) {
         if (this.field.captchaType == 'local') {
            const element = super.render(wrapper);
            const field = this.field.imageAttr
            const attr = { ...field.attributes, src: field.src };
            wrapper.appendChild(this.h.span(this.h.img(attr)));
            return element;
         }
         wrapper.appendChild(this.h.frag(this.field.html));
         return;
      }
   }
   /** @class
       @classdesc Renders a hidden field
       @extends Form/HTMLFieldText
       @alias Form/HTMLFieldHidden
   */
   class HTMLFieldHidden extends HTMLFieldText {
   }
   /** @class
       @classdesc Renders a password field
       @extends Form/HTMLFieldText
       @alias Form/HTMLFieldPassword
   */
   class HTMLFieldPassword extends HTMLFieldText {
      /** @function
          @desc Render a password input field
          @param {element} wrapper Container for the input element
          @return {element} Returns the input element
      */
      render(wrapper) {
         this.field.fif = '';
         const element = super.render(wrapper);
         if (this.field.reveal) {
            const id = this.field.id;
            const handler = function(event) {
               WCom.Form.Util.passwordReveal(id);
            };
            const attr = {
               className: 'reveal',
               onmouseover: handler,
               title: 'Toggle show password'
            };
            wrapper.appendChild(this.h.span(attr, '👁'));
         }
         return element;
      }
   }
   /** @class
       @classdesc Renders a textarea
       @extends Form/HTMLField
       @alias Form/HTMLFieldTextarea
   */
   class HTMLFieldTextarea extends HTMLField {
      /** @function
          @desc Render a textarea input field
          @param {element} wrapper Container for the input element
          @return {element} Returns the input element
      */
      render(wrapper) {
         if (this.field.cols) this.attr.cols = this.field.cols;
         if (this.field.rows) this.attr.rows = this.field.rows;
         const element = this.h.textarea(this.attr, this.field.fif);
         wrapper.appendChild(element);
         return element;
      }
   }
   /** @class
       @classdesc Renders an upload field
       @extends Form/HTMLField
       @alias Form/HTMLFieldUpload
   */
   class HTMLFieldUpload extends HTMLField {
      /** @function
          @desc Render a file upload field
          @param {element} wrapper Container for the input element
          @return {element} Returns the input element
      */
      render(wrapper) {
         this.attr.type = 'file';
         const element = this.h.input(this.attr);
         wrapper.appendChild(element);
         return element;
      }
   }
   /** @class
       @classdesc Form factory. {@link WCom.Util/Event Registers}
          the 'scan' method so that it is called when the page loads.
          Creates instances of {@link Form/HTMLForm HTMLForm}
       @alias Form/Factory
   */
   class Factory {
      constructor() {
         WCom.Util.Event.registerOnload(this.scan.bind(this));
      }
      /** @function
          @desc Scans the supplied DOM element for the form's trigger class
             which defaults to 'html-forms'. If a form with the trigger class
             is not found, forms of a given form class are scanned for
             instead
          @param {object} content DOM element to scan
          @param {object} options
          @property {string} options.formClass Non default form class to select
             Defaults to 'classic'
      */
      scan(content = document, options = {}) {
         let found = false;
         const els = content.getElementsByClassName(triggerClass);
         if (els) {
            for (const el of els) {
               const data = el.dataset[dsName];
               if (!data) next;
               const form = new HTMLForm(el, JSON.parse(data));
               form.render();
               found = true;
            }
         }
         if (found) return;
         const formClass = options.formClass ? options.formClass
                         : WCom.Form.Util.defaultFormClass;
         const forms = content.querySelector(`form.${formClass}`);
         if (!forms) return;
         for (const form of forms) {
            WCom.Form.DataStructure.scan(form);
            WCom.Form.Toggle.scan(form);
            this.animateButtons(form, '.input-field button');
            WCom.Form.Util.focusFirst(form);
         }
      }
   }
   Object.assign(Factory.prototype, WCom.Util.Markup);
   const factory = new Factory();
   /** @module Form
       @desc Scans for and creates instances of
          {@link Form/HTMLForm|HTMLform}. Renders the form
   */
   return {
      /** @function
          @see {@link Form/Factory#scan|Factory scan}
          @param {element} content
          @param {object} options
      */
      scan: factory.scan.bind(factory)
   };
})();
