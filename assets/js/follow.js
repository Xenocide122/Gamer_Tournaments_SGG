export default () => ({
  isFollowing: false,
  following: {
    ['x-show:transition:leave']() {
      return this.isFollowing;
    },

    ['x-transition:enter']: 'transition duration-500',
    ['x-transition:enter-start']: 'opacity-0 translate-x-20',
    ['x-transition:enter-end']: 'opacity-100 translate-x-0'
  },
  notFollowing: {
    ['x-show']() {
      return !this.isFollowing;
    },

    ['x-transition:enter']: 'transition-opacity duration-300',
    ['x-transition:enter-start']: 'opacity-0',
    ['x-transition:enter-end']: 'opacity-100'
  }
});
