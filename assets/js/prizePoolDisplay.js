export default () => ({
  ranks: Infinity,
  prizeWidths: [],
  seeMoreWidth: 0,
  trophyWidth: 0,
  showMore: false,

  init() {
    let prizes = this.$el.querySelector('.tournament-prizes').children;
    for (let i = 0; i < prizes.length; i++) {
      this.prizeWidths.push([
        prizes[i].getBoundingClientRect().width,
        parseInt(prizes[i].getAttribute('rank'))
      ]);
    }
    this.seeMoreWidth = this.$el
      .querySelector('[x-bind="seeMore"]')
      .getBoundingClientRect().width;
    this.trophyWidth = this.$el
      .querySelector('[x-bind="trophy"]')
      .getBoundingClientRect().width;

    this.resize();
  },

  resize: function () {
    let parentWidth = this.$el.parentElement.getBoundingClientRect().width;
    let myY = this.$el.getBoundingClientRect().y;
    let otherWidth = 0;
    for (
      let prev = this.$el.previousElementSibling;
      prev != null;
      prev = prev.previousElementSibling
    ) {
      let rect = prev.getBoundingClientRect();
      if (rect.y === myY) {
        otherWidth += rect.width;
      }
    }

    let widthMax = parentWidth - otherWidth - this.trophyWidth;
    let widthClippedMax = widthMax - this.seeMoreWidth;

    let width = 0;
    let clip = false;
    let clippedRank = -1;
    for (let i = 0; i < this.prizeWidths.length; i++) {
      width += this.prizeWidths[i][0];
      if (clippedRank === -1 && width > widthClippedMax) {
        clippedRank = this.prizeWidths[i][1];
      }
      if (width > widthMax) {
        clip = true;
        break;
      }
    }

    this.ranks = clip ? clippedRank : Infinity;
  },
  prize: {
    ['x-show']() {
      return parseInt(this.$el.getAttribute('rank')) < this.ranks;
    }
  },
  seeMore: {
    ['x-show']() {
      return this.ranks != Infinity;
    },
    ['@keydown.escape']() {
      this.showMore = false;
    }
  },
  seeMoreText: {
    ['x-text']() {
      return '+' + (this.prizeWidths.length - this.ranks).toString() + ' more';
    },
    ['@click']() {
      this.showMore = !this.showMore;
    }
  },
  seeMoreDropdown: {
    ['x-show']() {
      return this.showMore;
    },
    ['@click.outside']() {
      this.showMore = false;
    },

    ['x-transition:enter']: 'transition-opacity duration-100',
    ['x-transition:enter-start']: 'opacity-0',
    ['x-transition:enter-end']: 'opacity-100',
    ['x-transition:leave']: 'transition-opacity duration-100',
    ['x-transition:leave-start']: 'opacity-100',
    ['x-transition:leave-end']: 'opacity-0'
  },
  trophy: {}
});
