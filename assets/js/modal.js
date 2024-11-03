export default () => ({
  show: false,
  overlay: {
    ['x-transition:enter']: 'transition-opacity duration-120',
    ['x-transition:enter-start']: 'opacity-0',
    ['x-transition:enter-end']: 'opacity-100',
    ['x-transition:leave']: 'transition-opacity duration-120',
    ['x-transition:leave-start']: 'opacity-100',
    ['x-transition:leave-end']: 'opacity-0'
  }
});
