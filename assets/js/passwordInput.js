export default () => ({
  showPassword: false,
  button: {
    ['@click']() {
      return (this.showPassword = !this.showPassword);
    }
  },
  input: {
    ['x-bind:type']() {
      return this.showPassword ? 'text' : 'password';
    }
  }
});
