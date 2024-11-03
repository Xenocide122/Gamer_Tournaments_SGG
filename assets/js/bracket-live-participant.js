export default () => ({
  hoveredParticipantId: null,
  participantLabel: {
    ['@mouseleave']() {
      this.hoveredParticipantId = null;
    },
    ['@mouseover']() {
      this.hoveredParticipantId = this.$el.dataset.participantId;
    }
  }
});
