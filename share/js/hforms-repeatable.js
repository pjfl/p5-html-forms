// Package HForms.Repeatable
// Dependencies HForms.Util
if (!window.HForms) window.HForms = {};
HForms.Repeatable = (function() {
   const idPrefix = HForms.Util.wrapperIdPrefix;
   const addRemoveHandlers = function() {
      const rmElems = document.getElementsByClassName('remove-repeatable');
      for (const el of rmElems) {
         el.onclick = function(event) {
            const repElemId = this.dataset.repeatableElementId;
            if (repElemId) {
               const field = document.getElementById(idPrefix + repElemId);
               if (field && confirm('Remove?')) field.remove();
            }
            event.preventDefault();
         }.bind(el);
      };
   };
   const addAddHandlers = function(htmls, indexes, levels) {
      const addElems = document.getElementsByClassName('add-repeatable');
      for (const el of addElems) {
         el.onclick = function(event) {
            const repId = this.dataset.repeatableId;
            if (repId) {
               const wrapper = document.getElementById(idPrefix + repId);
               if (wrapper) {
                  const controls = wrapper.getElementsByClassName('controls');
                  if (controls) {
                     const html  = htmls[repId];
                     const level = levels[repId];
                     const regex = new RegExp('\{index-' + level + '\}',"g");
                     let   index = indexes[repId];
                     controls[0].innerHTML += html.replace(regex, index++);
                     indexes[repId] = index;
                     addRemoveHandlers();
                  }
               }
            }
            event.preventDefault();
         }.bind(el);
      }
   };
   return {
      initialise: function(htmls, indexes, levels) {
         HForms.Util.onReady(function() {
            addAddHandlers(htmls, indexes, levels);
            addRemoveHandlers();
         });
      }
   };
})();
