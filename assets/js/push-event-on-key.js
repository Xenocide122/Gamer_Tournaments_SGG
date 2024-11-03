export default () => {
  const PushEventOnKey = {
    mounted() {
      const { eventToPush, triggerKey, toComponent } = this.el.dataset;

      const pushEventToComponent = () => {
        this.pushEventTo(this.el, eventToPush, {});
      };

      const pushEventToLiveView = () => {
        this.pushEvent(eventToPush, {});
      };

      const handleKeyDownEvent = event => {
        if (event.key == triggerKey) {
          if (!!toComponent) {
            pushEventToComponent();
          } else {
            pushEventToLiveView();
          }
        }
      };

      this.el.addEventListener('keydown', event => handleKeyDownEvent(event));
    }
  };

  return { hooks: { PushEventOnKey } };
};
