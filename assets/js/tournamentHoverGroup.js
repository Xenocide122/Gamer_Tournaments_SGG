export default () => ({
  position: 0,
  numberTournaments: 0,
  hoverRight: false,
  hoverLeft: false,
  tournamentsPerScroll: 0,
  tournamentSize: 0,
  timedout: false,

  init() {
    this.getTournaments();
    this.resize();
  },

  resize() {
    let maxWidth = this.$root.getBoundingClientRect().width - 120;
    if (maxWidth > 1000) {
      this.tournamentsPerScroll = 4;
    } else if (maxWidth > 650) {
      this.tournamentsPerScroll = 3;
    } else if (maxWidth > 250) {
      this.tournamentsPerScroll = 2;
    } else {
      this.tournamentsPerScroll = 1;
    }

    this.tournamentSize =
      (maxWidth - (this.tournamentsPerScroll - 1) * 24) /
      this.tournamentsPerScroll;
    if (this.position > this.numberTournaments - this.tournamentsPerScroll)
      this.position = this.numberTournaments - this.tournamentsPerScroll;
    if (this.position < 0) this.position = 0;
  },

  getTournaments() {
    this.numberTournaments = parseInt(
      this.$root.getAttribute('number-tournaments')
    );
  },

  untimeout() {
    this.timedout = false;
  },

  pageIndicator: {
    ['x-show']() {
      return this.hoverRight || this.hoverLeft;
    },
    ['x-transition:enter']: 'transition duration-200 ease-linear',
    ['x-transition:enter-start']: 'opacity-0',
    ['x-transition:enter-end']: 'opacity-100',
    ['x-transition:leave']: 'transition duration-500 ease-linear',
    ['x-transition:leave-start']: 'opacity-100',
    ['x-transition:leave-end']: 'opacity-0'
  },

  bar: {
    ['x-bind:style']() {
      return (
        'transform: translate(' +
        (60 - this.position * (this.tournamentSize + 24)) +
        'px, 0);'
      );
    },
    ['x-bind:enable-interior-hover']() {
      return !this.timedout;
    }
  },

  tournamentContainer: {
    ['x-bind:style']() {
      return 'width: ' + this.tournamentSize + 'px;';
    }
  },

  pageRight: {
    ['@click']() {
      if (this.timedout) return;
      this.timedout = true;
      this.getTournaments();
      this.position =
        this.position + this.tournamentsPerScroll >
        this.numberTournaments - this.tournamentsPerScroll
          ? this.numberTournaments - this.tournamentsPerScroll
          : this.position + this.tournamentsPerScroll;
      if (this.position < 0) this.position = 0;
      setTimeout(() => {
        this.untimeout();
      }, 900);
    },
    ['@mouseover']() {
      this.hoverRight = true;
    },
    ['@mouseleave']() {
      this.hoverRight = false;
    },
    ['x-show']() {
      return this.position < this.numberTournaments - this.tournamentsPerScroll;
    },

    ['x-transition:enter']: 'transition duration-200 ease-linear',
    ['x-transition:enter-start']: 'opacity-0',
    ['x-transition:enter-end']: 'opacity-100',
    ['x-transition:leave']: 'transition duration-200 ease-linear',
    ['x-transition:leave-start']: 'opacity-100',
    ['x-transition:leave-end']: 'opacity-0'
  },
  pageLeft: {
    ['@click']() {
      if (this.timedout) return;
      this.timedout = true;
      this.getTournaments();
      this.position =
        this.position - this.tournamentsPerScroll < 0
          ? 0
          : this.position - this.tournamentsPerScroll;
      setTimeout(() => {
        this.untimeout();
      }, 900);
    },
    ['@mouseover']() {
      this.hoverLeft = true;
    },
    ['@mouseleave']() {
      this.hoverLeft = false;
    },
    ['x-show']() {
      return this.position > 0;
    },

    ['x-transition:enter']: 'transition duration-200 ease-linear',
    ['x-transition:enter-start']: 'opacity-0',
    ['x-transition:enter-end']: 'opacity-100',
    ['x-transition:leave']: 'transition duration-200 ease-linear',
    ['x-transition:leave-start']: 'opacity-100',
    ['x-transition:leave-end']: 'opacity-0'
  }
});
