export default () => ({
  open: false,

  removeTrigger: {
    ['@click']() {
      return (this.open = true);
    },
    ['x-show']() {
      return !this.open;
    }
  },
  remove: {
    ['@click']() {
      return (this.open = false);
    },
    ['x-show']() {
      return this.open;
    },
    ['x-transition:enter']: 'transition-[max-width, opacity] duration-200',
    ['x-transition:enter-start']: 'max-w-0 opacity-50',
    ['x-transition:enter-end']: 'max-w-[20vh] opacity-100',
    ['x-transition:leave']: 'transition-[max-width, opacity] duration-200',
    ['x-transition:leave-start']: 'max-w-[20vh] opacity-100',
    ['x-transition:leave-end']: 'max-w-0 opacity-0'
  },
  removeClose: {
    ['@click']() {
      return (this.open = false);
    },
    ['x-show']() {
      return this.open;
    }
  }
});
