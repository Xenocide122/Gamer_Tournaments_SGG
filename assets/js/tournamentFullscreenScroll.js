export default () => ({
  position: 0,
  oldPosition: -1,
  numberTournaments: 0,

  init() {
    this.getTournaments();
  },

  getTournaments() {
    this.numberTournaments = parseInt(
      this.$root.getAttribute('number-tournaments')
    );
  },

  getPos(el) {
    return parseInt(el.closest('[value]').getAttribute('value'));
  },

  cardBackground: {
    ['x-show']() {
      let mypos = this.getPos(this.$el);
      return this.position == mypos || this.oldPosition == mypos;
    },

    ['x-bind:class']() {
      return this.getPos(this.$el) == this.position ? 'z-[1]' : 'z-0';
    },

    ['x-transition:enter']: 'transition duration-300',
    ['x-transition:enter-start']: 'opacity-0',
    ['x-transition:enter-end']: 'opacity-100'
  },
  cardText: {
    ['x-show']() {
      return this.position == this.getPos(this.$el);
    }
  },

  pageLeft: {
    ['@click']() {
      this.pageTo(
        (this.position == 0 ? this.numberTournaments : this.position) - 1
      );
    }
  },

  pageRight: {
    ['@click']() {
      this.pageTo((this.position + 1) % this.numberTournaments);
    }
  },

  pageTo(i) {
    if (this.oldPosition >= 0) return;
    this.oldPosition = this.position;
    this.position = i;
    setTimeout(() => {
      this.oldPosition = -1;
    }, 300);
  }
});
