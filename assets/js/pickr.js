import flatpickr from 'flatpickr';

const Pickr = {
  mounted() {
    const pushEventToComponent = (event, payload) => {
      this.pushEventTo(this.el, event, payload);
    };

    this.pickr = flatpickr(this.el, {
      onChange: function (fancy, date, instance) {
        pushEventToComponent('date-picked', { dob: date });
      },
      wrap: true,
      altInput: this.el.dataset.pickrAltFormat ? true : false,
      altFormat: this.el.dataset.pickrAltFormat || 'd M Y',
      dateFormat: this.el.dataset.pickrDateFormat || 'Y-m-d'
    });
  }
};

export default Pickr;
