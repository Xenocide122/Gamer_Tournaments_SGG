export default () => {
  const FlashInfo = {
    mounted() {
      const lifespan = parseInt(this.el.dataset.lifespan);

      const pushEventToComponent = (event, payload) => {
        this.pushEventTo(this.el, event, payload);
      };

      lifespan &&
        setTimeout(() => {
          pushEventToComponent('lv:clear-flash', { key: 'info' });
        }, lifespan);
    }
  };

  const FlashError = {
    mounted() {
      const lifespan = parseInt(this.el.dataset.lifespan);

      const pushEventToComponent = (event, payload) => {
        this.pushEventTo(this.el, event, payload);
      };

      lifespan &&
        setTimeout(() => {
          pushEventToComponent('lv:clear-flash', { key: 'error' });
        }, lifespan);
    }
  };

  return { hooks: { FlashInfo, FlashError } };
};
