export default () => ({
  height: 0,
  init() {
    this.resize();
  },

  resize: function () {
    const navvy = document.querySelector('.navbar');
    if (navvy) {
      const rect = document.getBoundingClientRect();
      if (rect && rect.height) {
        this.height = rect.height;
      }
    }
  }
});
