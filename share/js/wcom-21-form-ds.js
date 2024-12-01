// Package WCom.Form.DataStructure
// Dependencies WCom.Util WCom.Form.Util
WCom.Form.DataStructure = (function() {
   const dsName       = 'dsSpecification';
   const triggerClass = 'data-structure';
   class Drag {
      constructor(args = {}) {
         this.drag = {};
         this.dragNodeX = null;
         this.dragNodeY = null;
         const wrapperId = args.wrapperId || '#frame';
         this.scrollableWrapper = document.querySelector(wrapperId);
         this.dragHandler = this._dragHandler.bind(this);
         this.dropHandler = this._dropHandler.bind(this);
      }
      autoScrollHandler(event) {
         const threshold = this.drag.autoScroll;
         if (!threshold || threshold < 1) return;
         const y = event.pageY;
         const minY = document.body.scrollTop;
         const maxY = minY + this.drag.viewportHeight;
         let scrollDirn = 'noScroll';
         if (y + threshold > maxY) scrollDirn = 'down';
         if (y - threshold < minY) scrollDirn = 'up';
         if (this.drag.scrollDirection != scrollDirn) {
            this.drag.scrollDirection = scrollDirn;
            this.setScrollInterval();
         }
      }
      clearScrollInterval() {
         if (this.drag.scrollInterval) clearInterval(this.drag.scrollInterval);
      }
      _dragHandler(event) {
         const drag = this.drag;
         if (drag.autoScroll) this.autoScrollHandler(event);
         if (drag.moveCallback) drag.moveCallback(event, drag.dragNode);
         if (drag.updateDropNodePositions) this.updateDropNodePositions();
         this.dragNodeX = event.pageX;
         this.dragNodeY = event.pageY;
         if (drag.fixLeft) this.dragNodeX = drag.fixLeft;
         const constraints = drag.constraints;
         if (constraints) {
            if (constraints.top)
               this.dragNodeY = Math.max(this.dragNodeY, constraints.top);
            if (constraints.bottom)
               this.dragNodeY = Math.min(this.dragNodeY, constraints.bottom);
            if (constraints.left)
               this.dragNodeX = Math.max(this.dragNodeX, constraints.left);
            if (constraints.right)
               this.dragNodeX = Math.min(this.dragNodeX, constraints.right);
         }
         this.updateHoverNode(event);
         if (drag.dragNodeOffset) {
            this.dragNodeX -= drag.dragNodeOffset.x;
            this.dragNodeY -= drag.dragNodeOffset.y;
         }
         if (drag.dragNode) {
            const tableOffset = drag.table
                  ? this.h.getOffset(drag.table) : { left: 0, top: 0 };
            drag.dragNode.style.left
               = (this.dragNodeX - tableOffset.left) + 'px';
            drag.dragNode.style.top
               = (this.dragNodeY - tableOffset.top) + 'px';
         }
      }
      _dropHandler(event) {
         const node = this.drag.currentDropNode;
         if (node) this.leaveHandler(event, node);
         if (this.drag.dropCallback)
            this.drag.dropCallback(node, this.drag.dragNode);
         this.stop();
      }
      hoverHandler(event, node) {
         if (this.drag.hoverClass) node.classList.add(this.drag.hoverClass);
         if (this.drag.hoverCallback)
            this.drag.hoverCallback(node, this.drag.dragNode, true);
      }
      leaveHandler(event, node) {
         if (this.drag.hoverClass) node.classList.remove(this.drag.hoverClass);
         if (this.drag.hoverCallback)
            this.drag.hoverCallback(node, this.drag.dragNode, false);
      }
      setScrollInterval() {
         this.clearScrollInterval();
         const dirn = this.drag.scrollDirection;
         if (dirn == 'noScroll') return;
         const scrollBy = dirn == 'down'
               ? this.drag.autoScrollStep : -this.drag.autoScrollStep;
         this.drag.scrollInterval = setInterval(function() {
            this.scrollableWrapper.scrollBy(0, scrollBy);
         }.bind(this), this.drag.autoScrollSpeed);
      }
      state() {
         return this.drag;
      }
      start(event, settings = {}) {
         if (!event) throw new Error('You must supply an event');
         event.preventDefault();
         this.stop();
         const autoScroll = settings.autoScroll == true ? 80
               : settings.autoScroll || false;
         const body = document.body;
         const html = document.documentElement;
         const height = Math.max(
            body.scrollHeight, body.offsetHeight,
            html.clientHeight, html.scrollHeight, html.offsetHeight
         );
         this.drag = {
            autoScroll: autoScroll,
            autoScrollSpeed: (settings.autoScrollSpeed || 10),
            autoScrollStep: (settings.autoScrollStep || 5),
            constraints: settings.constraints,
            currentDropNode: null,
            documentHeight: height,
            dragNode: settings.dragNode,
            dragNodeOffset: settings.dragNodeOffset,
            dropCallback: settings.dropCallback,
            dropNodes: settings.dropTargets,
            fixLeft: settings.fixLeft,
            hoverCallback: settings.hoverCallback,
            hoverClass: settings.hoverClass,
            moveCallback: settings.moveCallback,
            table: settings.table,
            touchEvents: settings.touchEvents,
            viewportHeight: window.innerHeight
         };
         if (settings.offsetDragNode) {
            const pos = this.h.getOffset(event.target);
            this.drag.dragNodeOffset = {
               x: Math.round(event.pageX - pos.left),
               y: Math.round(event.pageY - pos.top)
            };
         }
         const dragNode = this.drag.dragNode;
         if (dragNode) {
            dragNode.addEventListener('mousemove', this.dragHandler);
            dragNode.addEventListener('mouseup', this.dropHandler);
         }
         // TODO: Add document.onwheel and scrollableWrapper.onscroll events
         this.updateDropNodePositions();
         this.dragHandler(event);
      }
      stop() {
         this.clearScrollInterval();
         const dragNode = this.drag.dragNode;
         if (dragNode) {
            dragNode.removeEventListener('mousemove', this.dragHandler);
            dragNode.removeEventListener('mouseup', this.dropHandler);
            dragNode.style.left = null;
            dragNode.style.top = null;
         }
         this.drag = {};
         // TODO: Remove wheel/scroll events
      }
      updateDropNodePositions() {
         this.drag.dropNodePositions = [];
         for (const dropNode of this.drag.dropNodes) {
            const pos = this.h.getOffset(dropNode);
            this.drag.dropNodePositions.push({
               node: dropNode,
               bottom: Math.round(pos.top + dropNode.offsetHeight),
               left: Math.round(pos.left),
               right: Math.round(pos.left + dropNode.offsetWidth),
               top: Math.round(pos.top)
            });
         }
         this.drag.updateDropNodePositions = false;
      }
      updateHoverNode(event) {
         let hoverNode = null;
         for (const target of this.drag.dropNodePositions) {
            if (this.dragNodeX > target.left &&
                this.dragNodeX < target.right &&
                this.dragNodeY > target.top &&
                this.dragNodeY < target.bottom &&
                target.node != this.drag.dragNode) {
               hoverNode = target.node;
               break;
            }
         }
         const dropNode = this.drag.currentDropNode;
         if (hoverNode != dropNode) {
            if (dropNode) this.leaveHandler(event, dropNode);
            if (hoverNode) this.hoverHandler(event, hoverNode);
            this.drag.currentDropNode = hoverNode;
         }
      }
   }
   Object.assign(Drag.prototype, WCom.Util.Markup);
   class DataStructure {
      constructor(container) {
         this.container = container;
         this.hidden = this.container.querySelector('input[type=hidden]');
         const config = this.hidden.dataset[dsName];
         this.config = config ? JSON.parse(config) : {};
         this.dragTitle = this.config['drag-title'] || 'Drag to reorder';
         this.fixed = this.config['fixed'] || false;
         this.icons = this.config['icons'];
         this.isObject = this.config['is-object'] || false;
         this.readonly = this.config['readonly'];
         this.reorderable = this.config['reorderable'] || false;
         this.rowClass = this.config['row-class'] || '';
         this.structure = this.config['structure'];
         this.drag = new Drag();
         this.hasLoaded = false;
         this.identifier = Math.random().toString().replace(/\D+/g, '');
         this.mousedownHandler = this._mousedownHandler.bind(this);
         this.submitHandler = this._submitHandler.bind(this);
         const data = this.hidden.value ? JSON.parse(this.hidden.value) : [];
         const isArray = Array.isArray(data);
         if (this.config['single-hash']) {
            this.singleRow = true;
            this.sourceData = isArray ? [data[0]] : [data];
         }
         else if (typeof data == 'object' && !isArray) {
            this.sourceData = Object.keys(data).sort(function(a, b) {
               return a.toLowerCase().localeCompare(b.toLowerCase());
            }).map(function(key) {
               return { name: key, value: data[key] };
            });
         }
         else this.sourceData = data;
         this.fieldRenderer = {
            // TODO: More field types
            datetime: function(specification, value = '') {
               const el = this.h.input({
                  className: 'input input-datetime ds-input',
                  type: 'datetime-local',
                  value
               });
               el.setAttribute('data-ds-name', specification['name']);
               if (specification['readonly'])
                  el.setAttribute('readonly', 'readonly');
               return el;
            }.bind(this),
            display: function(specification, value = '') {
               const el = this.h.span({
                  className: 'output output-display ds-output'
               }, value);
               el.setAttribute('data-ds-name', specification['name']);
               return el;
            }.bind(this),
            hidden: function(specification, value = '') {
               const el = this.h.hidden({
                  className: 'input input-hidden ds-input', value
               });
               el.setAttribute('data-ds-name', specification['name']);
               if (specification['readonly'])
                  el.setAttribute('readonly', 'readonly');
               return el;
            }.bind(this),
            text: function(specification, value = '') {
               const el = this.h.text({
                  className: 'input input-text ds-input', value
               });
               el.setAttribute('data-ds-name', specification['name']);
               if (specification['readonly'])
                  el.setAttribute('readonly', 'readonly');
               return el;
            }.bind(this),
            textarea: function(specification, value = '') {
               const el = this.h.textarea({
                  className: 'input input-textarea ds-input', value
               });
               el.setAttribute('data-ds-name', specification['name']);
               if (specification['readonly'])
                  el.setAttribute('readonly', 'readonly');
               return el;
            }.bind(this)
         };
         const form = this.hidden.form;
         if (form) form.addEventListener('submit', this.submitHandler);
      }
      _closestRow(el) {
         while (el && el.tagName != 'TR') el = el.parentNode;
         return el;
      }
      createField(specification, item) {
         const useDefault = !item;
         item ||= {};
         let value = item[specification.name];
         if (!value && specification.readonly) return;
         if (useDefault) value = specification.value;
         const renderer = this.fieldRenderer[specification.type];
         if (!renderer) return;
         const field = renderer.call(this, specification, value, item);
         if (this.isObject) this.registerValidation(field, specification.name);
         return field;
      }
      createRow(item, index) {
         const readonly = this.readonly[index];
         const row = this.h.tr({ className: this.rowClass });
         const fields = {};
         let tag;
         for (const column of this.structure) {
            const field = this.createField(column, item);
            if (!field) continue;
            if (readonly) field.setAttribute('readonly', 'readonly');
            if (column.tag) {
               if (tag) tag.appendChild(field);
               else {
                  tag = this.h.span({ className: 'ds-tag' }, field);
                  fields[column.tag].prepend(tag);
               }
            }
            else {
               const className = 'ds-field'
                     + (column.classes ? ' ' + column.classes : '');
               fields[column.name] = this.h.td({ className }, field);
               row.appendChild(fields[column.name]);
            }
         }
         if (this.reorderable) {
            const icon = this.h.icon({
               name: 'grab', className: 'drag-icon', icons: this.icons
            });
            const knob = this.h.span({
               className: 'knob', title: this.dragTitle
            }, icon);
            row.appendChild(this.h.td({ className: 'ds-reorderable' }, knob));
         }
         if (!this.singleRow && !this.fixed && !readonly) {
            const button = this.h.button({
               className: 'small',
               onclick: function(event) {
                  this._closestRow(event.target).remove();
               }.bind(this)
            }, 'Delete');
            row.appendChild(this.h.td({ className: 'ds-remove' }, button));
         }
         this.table.querySelector('tbody').appendChild(row);
      }
      dropCallback(tr, row, dropTarget) {
         const selected = row.querySelector(
            'td > input[data-ds-name="selected"]'
         );
         if (selected && selected.getAttribute('checked')) {
            selected.removeAttribute('checked');
            const cells = tr.querySelectorAll(
               'td > input[data-ds-name="selected"]'
            );
            for (const cell of cells) {
               cell.setAttribute('checked', 'checked');
            }
         }
         row.remove();
         if (dropTarget.parentNode)
            dropTarget.parentNode.replaceChild(tr, dropTarget);
         for (const cell of tr.querySelectorAll('td'))
            cell.classList.remove('hide');
         // TODO: Drop highlight. Also where highlight come from?
      }
      getValue() {
         const errors = [];
         const data = (this.isObject) ? {} : [];
         for (const row of this.table.querySelectorAll('tr')) {
            if (row.querySelectorAll('th').length) continue;
            const item = {};
            if (this.isObject) {
               const nameEl = row.querySelector('[data-ds-name="name"]');
               const name = nameEl.value;
               const validation = this.isValidName(name);
               if (!validation.valid) {
                  nameEl.classList.add('ds-error');
                  for (const error of validation.errors) {
                     if (errors.indexOf(error) == -1) errors.push(error);
                  }
               }
               const valueEl = row.querySelector('[data-ds-name="value"]');
               const type = valueEl.getAttribute('type');
               const value = type == 'radio' || type == 'checkbox'
                     ? (valueEl.getAttribute('checked') ? valueEl.value : '')
                     : valueEl.value;
               data[name] = value;
            }
            else {
               for (const cell of row.querySelectorAll('.ds-field')) {
                  const field = cell.querySelector('.ds-input');
                  const name = field.getAttribute('data-ds-name');
                  const type = field.getAttribute('type');
                  const value = type == 'radio' || type == 'checkbox'
                        ? (field.getAttribute('checked') ? field.value : '')
                        : field.value;
                  item[name] = value;
               }
               data.push(item);
            }
         }
         if (this.isObject && errors.length) return { errors, valid: false };
         return { content: (this.singleRow ? data[0] : data), valid: true };
      }
      isValidName(name) {
         const result = { errors: [], valid: true };
         if (!name) {
            result.errors.push('Name is required');
            result.valid = false;
         }
         const query = `[data-ds-name="${name}"]`;
         const names = this.container.querySelectorAll(query).map(function(el) {
            return el.value;
         });
         const isDup = names.filter(function(n) { return name == n }).length > 1;
         if (isDup) {
            result.errors.push('Duplicate names are not allowed');
            result.valid = false;
         }
         return result;
      }
      _mousedownHandler(event) {
         event.preventDefault();
         const eventRow = this._closestRow(event.target);
         const height = eventRow.offsetHeight;
         const dragNode = eventRow.cloneNode(true);
         dragNode.style.width = (eventRow.offsetWidth - 1) + 'px';
         dragNode.classList.add('ds-reorderable-drag');
         const cells = dragNode.querySelectorAll('td');
         let index = 0;
         for (const cell of eventRow.querySelectorAll('td')) {
            cells[index++].style.width = cell.offsetWidth + 'px';
            cell.classList.add('hide');
         }
         const table = this.table;
         const tableOffset = this.h.getOffset(table);
         const tbody = table.querySelector('tbody');
         tbody.prepend(dragNode);
         const dropTarget = this.h.tr({
            className: 'ds-reorderable-drop'
         }, this.h.td({ colSpan: cells.length }));
         dropTarget.style.height = height + 'px';
         eventRow.parentNode.insertBefore(dropTarget, eventRow.nextSibling);
         this.drag.start(event, {
            autoScroll: true,
            constraints: {
               top: tableOffset.top - 2,
               bottom: tableOffset.top + table.offsetHeight - 2
            },
            dragNode,
            dragNodeOffset: { x: 0, y: 10 },
            dropCallback: function(dropNode, dragNode) {
               this.dropCallback(eventRow, dragNode, dropTarget)
            }.bind(this),
            dropTargets: table.querySelectorAll('tr'),
            fixLeft: this.h.getOffset(eventRow).left + 1,
            table,
            hoverCallback: function(hoverNode, dragNode, isHover) {
               if (hoverNode.tagName == 'THEAD') tbody.prependChild(dropTarget);
               else hoverNode.parentNode.insertBefore(
                  dropTarget, hoverNode.nextSibling
               );
            }.bind(this)
         });
      }
      _header() {
         const row = this.h.tr();
         const header = this.h.thead({}, row);
         for (const column of this.structure)
            row.appendChild(this.h.th(column.label));
         if (this.reorderable) row.appendChild(this.h.th());
         if (!this.fixed) row.appendChild(this.h.th());
         return header;
      }
      render() {
         const attr = { className: 'ds-form hide' };
         const table = this.h.table(attr, [this._header(), this.h.tbody()]);
         this.table = this.display(this.container, 'table', table);
         let index = 0;
         if (this.singleRow) this.createRow(this.sourceData[0], index);
         else {
            for (const item of this.sourceData) this.createRow(item, index++);
         }
         this.setupReorderable();
         this.table.classList.remove('hide');
         if (!this.singleRow && !this.fixed && !this.hasLoaded) {
            const addButton = this.h.button({
               className: 'small',
               onclick: function(event) {
                  event.preventDefault();
                  this.createRow();
                  this.setupReorderable();
                  const trigger = this.container.dataset['dsAddRow'];
                  if (trigger) trigger();
               }.bind(this)
            }, 'Add');
            this.container.appendChild(addButton);
            this.hasLoaded = true;
         }
      }
      registerValidation(field, name) {
         if (name != 'name') return;
         field.addEventListener('input', function(event) {
            const isValid = this.isValidName(this.value).valid;
            if (isValid) this.classList.remove('ds-error');
            else this.classList.add('ds-error');
         }.bind(this));
      }
      setupReorderable() {
         const knobs = '.ds-reorderable .knob';
         for (const knob of this.container.querySelectorAll(knobs)) {
            if (knob.getAttribute('mousedownlistener')) continue;
            knob.addEventListener('mousedown', this.mousedownHandler);
            knob.setAttribute('mousedownlistener', true);
         }
      }
      _submitHandler(event) {
         const value = this.getValue();
         if (value.valid) this.hidden.value = JSON.stringify(value.content);
         else {
            event.preventDefault();
            WCom.Modal.createAlert({
               icon: 'error',
               text: value.errors.join(', '),
               title: 'Errors in ' + this.title
            });
         }
      }
   }
   Object.assign(DataStructure.prototype, WCom.Util.Markup);
   class Manager {
      constructor() {
         this.ds = {};
      }
      async reload(target, url) {
         const ds = this.ds[target];
         const response = await fetch(url, { method: 'GET' });
         ds.sourceData = await response.json();
         ds.render();
      }
      scan(container = document) {
         for (const el of container.querySelectorAll(`div.${triggerClass}`)) {
            const ds = new DataStructure(el);
            this.ds[el.firstElementChild.id] = ds;
            ds.render();
         }
      }
   }
   const manager = new Manager();
   return {
      manager: manager,
      reload: manager.reload,
   };
})();
