export default () => ({
  isOpen: false,
  close() {
    return (this.isOpen = false);
  },
  trigger: {
    ['@click']() {
      return (this.isOpen = !this.isOpen);
    },
    ['@keydown.escape']() {
      return this.close();
    }
  },
  menu_wrapper: {
    ['x-show']() {
      return this.isOpen;
    },
    ['@click.outside']() {
      return this.close();
    },
    ['@keydown.escape']() {
      return this.close();
    }
  },
  menu: {
    ['x-show']() {
      return this.isOpen;
    }
  }
});
