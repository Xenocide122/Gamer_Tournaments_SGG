export default () => ({
  darkMode:
    localStorage.getItem('dark') === 'true' ||
    (localStorage.getItem('dark') === null &&
      window.matchMedia('(prefers-color-scheme: dark)').matches),
  init() {
    this.$watch('darkMode', value => localStorage.setItem('dark', value));
  },
  toggleDarkMode() {
    this.darkMode = !this.darkMode;
  },
  classes: {
    ['x-bind:class']() {
      return this.darkMode ? 'dark' : '';
    }
  }
});
