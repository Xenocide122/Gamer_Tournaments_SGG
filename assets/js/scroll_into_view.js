export default () => {
  const ScrollIntoView = {
    mounted() {
      const scrollOptions = {
        alignToTop: false,
        block: 'end',
        inline: 'start'
      };
      document.getElementById(this.el.id).scrollIntoView(scrollOptions);
    }
  };
  return { hooks: { ScrollIntoView } };
};
