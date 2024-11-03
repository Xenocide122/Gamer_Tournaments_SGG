export default () => ({
  round: 0,
  showMatches: false,
  trigger: {
    ['@click']() {
      this.showMatches = !this.showMatches;
    }
  },
  matchDetails: {
    ['x-show']() {
      return this.showMatches;
    },

    ['x-transition:enter']: 'transition-opacity duration-100',
    ['x-transition:enter-start']: 'opacity-0',
    ['x-transition:enter-end']: 'opacity-100',
    ['x-transition:leave']: 'transition-opacity duration-100',
    ['x-transition:leave-start']: 'opacity-100',
    ['x-transition:leave-end']: 'opacity-0'
  }
});
