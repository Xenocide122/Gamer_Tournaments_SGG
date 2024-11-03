export default () => ({
  position: 0,
  right: true,

  init() {
    this.$watch('position', (pos, oldpos) => this.clickTo(pos, oldpos));
  },
  pane: {
    ['x-show']() {
      return parseInt(this.$el.getAttribute('position')) === this.position;
    },

    ['x-bind:class']() {
      return this.right ? 'scroll-right' : 'scroll-left';
    },

    ['x-transition:enter']: 'transition duration-300',
    ['x-transition:enter-start']: 'opacity-0 scroll',
    ['x-transition:enter-end']: 'opacity-100 translate-x-0'
  },
  clickTo(pos, oldpos) {
    this.right = pos > oldpos;
  },
  menuItem: {
    ['@click']() {
      this.position = parseInt(this.$el.getAttribute('value'));
    }
  }
});
