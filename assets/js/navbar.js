export default () => ({
  // SEARCH BAR
  searchOpen: false,
  toggleSearch() {
    if (this.searchOpen) {
      return this.closeSearch();
    } else {
      return this.openSearch();
    }
  },
  openSearch() {
    this.$refs.searchTrigger.focus();
    this.searchOpen = true;
    this.$nextTick(() => this.$refs.searchInput.focus());
  },
  closeSearch(focusAfter) {
    if (!this.searchOpen) return;
    this.searchOpen = false;
    focusAfter && focusAfter.focus();
  },
  searchTrigger: {
    ['x-ref']: 'searchTrigger',
    ['x-on:click']: 'toggleSearch()'
  },
  searchBar: {
    ['x-cloak']: true,
    ['x-show']: 'searchOpen'
  },
  // MOBILE MENU
  mobileMenuOpen: false,
  toggleMobileMenu() {
    if (this.mobileMenuOpen) {
      return this.closeMobileMenu();
    }
    this.$refs.mobileMenuTrigger.focus();
    this.mobileMenuOpen = true;
  },
  closeMobileMenu(focusAfter) {
    if (!this.mobileMenuOpen) return;
    this.mobileMenuOpen = false;
    focusAfter && focusAfter.focus();
  },
  mobileMenuTrigger: {
    ['x-ref']: 'mobileMenuTrigger',
    ['x-on:click']: 'toggleMobileMenu()'
  },
  mobileMenuBackdrop: {
    ['x-cloak']: true,
    ['x-show']: 'mobileMenuOpen',
    ['x-transition:enter']: 'transition ease-in-out duration-150',
    ['x-transition:enter-start']: 'opacity-0',
    ['x-transition:enter-end']: 'opacity-100',
    ['x-transition:leave']: 'transition ease-in-out duration-150',
    ['x-transition:leave-start']: 'opacity-100',
    ['x-transition:leave-end']: 'opacity-0'
  },
  mobileMenu: {
    ['x-cloak']: true,
    ['x-show']: 'mobileMenuOpen',
    ['x-on:click.outside']: 'closeMobileMenu($refs.mobileMenuTrigger)',
    ['x-transition:enter']: 'transition ease-in-out duration-150',
    ['x-transition:enter-start']: 'transform -translate-y-full',
    ['x-transition:enter-end']: 'transform translate-y-0',
    ['x-transition:leave']: 'transition ease-in-out duration-150',
    ['x-transition:leave-start']: 'transform translate-y-0',
    ['x-transition:leave-end']: 'transform -translate-y-full'
  }
});
