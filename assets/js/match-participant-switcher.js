const poolStageTypes = ['swiss', 'pool'];
window.addEventListener(
  'phx:created_match_participant',
  ({
    detail: {
      mp_id: mp_id,
      tp_id: tp_id,
      match_type: match_type,
      match_id: match_id,
      group: group
    }
  }) => {
    const matchOrGroupSuffix = poolStageTypes.includes(match_type)
      ? `group-${group}`
      : `match-${match_id}`;
    const switcherId = `match-participant-switcher-null-${matchOrGroupSuffix}`;
    const switcher = document.getElementById(switcherId);
    if (switcher) {
      switcher.value = tp_id;
      switcher.id = `match-participant-switcher-${mp_id}-${matchOrGroupSuffix}`;
    }
  }
);
window.addEventListener(
  'phx:updated_other_match_participant',
  ({
    detail: {
      mp_id: mp_id,
      tp_id: tp_id,
      match_type: match_type,
      match_id: match_id,
      group: group
    }
  }) => {
    const matchOrGroupSuffix = poolStageTypes.includes(match_type)
      ? `group-${group}`
      : `match-${match_id}`;
    const switcherId = `match-participant-switcher-${mp_id}-${matchOrGroupSuffix}`;
    const switcher = document.getElementById(switcherId);
    if (switcher) {
      switcher.value = tp_id;
      if (tp_id === null) {
        switcher.id = `match-participant-switcher-${null}-${matchOrGroupSuffix}`;
      }
    }
  }
);
window.addEventListener(
  'phx:deleted_match_participant',
  ({
    detail: {
      mp_id: mp_id,
      match_type: match_type,
      match_id: match_id,
      group: group
    }
  }) => {
    const matchOrGroupSuffix = poolStageTypes.includes(match_type)
      ? `group-${group}`
      : `match-${match_id}`;
    const switcherId = `match-participant-switcher-${mp_id}-${matchOrGroupSuffix}`;
    const switcher = document.getElementById(switcherId);
    if (switcher) {
      switcher.selectedIndex = 0;
      switcher.id = `match-participant-switcher-${null}-${matchOrGroupSuffix}`;
    }
  }
);
window.addEventListener(
  'phx:reset_null_switcher_value',
  ({ detail: { mp_id: mp_id, group: group } }) => {
    const matchOrGroupSuffix = `group-${group}`;
    const mpSwitcherId = `match-participant-switcher-${mp_id}-${matchOrGroupSuffix}`;
    const nullSwitcherId = `match-participant-switcher-${null}-${matchOrGroupSuffix}`;
    const switcher =
      document.getElementById(nullSwitcherId) ||
      document.getElementById(mpSwitcherId);
    if (switcher) {
      switcher.selectedIndex = 0;
    }
  }
);
