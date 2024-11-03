// import Sortable from 'sortablejs';
import { Sortable, Swap } from 'sortablejs/modular/sortable.core.esm';

Sortable.mount(new Swap());

export default () => {
  const SortableHook = {
    mounted() {
      const pushEventToComponent = (event, payload) => {
        this.pushEventTo(this.el, event, payload);
      };

      const {
        showSpinnerOnDrop,
        sortableGroup,
        useSwapPlugin,
        eventToSendOnDrop
      } = this.el.dataset;

      const onEnd = evt => {
        if (showSpinnerOnDrop && evt.from.id != evt.to.id) {
          window.dispatchEvent(new Event('phx:show-spinner'));
        }

        pushEventToComponent(eventToSendOnDrop, {
          from: evt.from.id,
          id: evt.item.id,
          index: evt.newDraggableIndex,
          to: evt.to.id
        });
      };

      Sortable.create(this.el, {
        swap: !!useSwapPlugin,
        handle: '.sortable-handle',
        filter: '.sortable-filtered',
        animation: 150,
        delay: 50,
        group: sortableGroup,
        delayOnTouchOnly: true,
        draggable: '.draggable',
        ghostClass: 'sortable-ghost',
        swapClass: 'sortable-swap-highlight', // Class name for swap item (if swap mode is enabled)
        onEnd
      });
    }
  };

  return { hooks: { Sortable: SortableHook } };
};
