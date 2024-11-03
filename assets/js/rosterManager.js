export default () => ({
  rosterOpen: false,
  addMemberOpen: false,

  rosterTrigger: {
    ['@click']() {
      this.addMemberOpen = false;
      return (this.rosterOpen = !this.rosterOpen);
    }
  },
  rosterWrapper: {
    ['x-show']() {
      return this.rosterOpen;
    },
    ['@click.outside']() {
      return (this.rosterOpen = false);
    }
  },
  roster: {
    ['x-show']() {
      return this.rosterOpen;
    },

    ['x-transition:enter']:
      'transition-[max-height, opacity] duration-300 ease-in',
    ['x-transition:enter-start']: 'max-h-0 opacity-50',
    ['x-transition:enter-end']: 'max-h-[40vh] opacity-100'
  },
  rosterChevronDown: {
    ['x-show']() {
      return this.rosterOpen;
    },
    ['x-transition:enter']: 'transition-transform duration-300',
    ['x-transition:enter-start']: '-rotate-90',
    ['x-transition:enter-end']: 'rotate-0'
  },
  rosterChevronRight: {
    ['x-show']() {
      return !this.rosterOpen;
    },
    ['x-transition:enter']: 'transition-transform duration-300',
    ['x-transition:enter-start']: 'rotate-90',
    ['x-transition:enter-end']: 'rotate-0'
  },

  addMemberTrigger: {
    ['@click']() {
      return (this.addMemberOpen = !this.addMemberOpen);
    }
  },
  addMemberWrapper: {
    ['x-show']() {
      return this.addMemberOpen;
    },
    ['@click.outside']() {
      return (this.addMemberOpen = false);
    }
  },
  addMember: {
    ['x-show']() {
      return this.addMemberOpen;
    },

    ['x-transition:enter']: 'transition-opacity duration-100',
    ['x-transition:enter-start']: 'opacity-0',
    ['x-transition:enter-end']: 'opacity-100',
    ['x-transition:leave']: 'transition-opacity duration-100',
    ['x-transition:leave-start']: 'opacity-100',
    ['x-transition:leave-end']: 'opacity-0'
  },
  rosterAutoClose: {
    ['@close-roster']() {
      this.addMemberOpen = false;
      return (this.rosterOpen = false);
    }
  }
});
