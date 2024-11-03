import { Graph } from '@antv/x6';

const zoomFactor = 0.08;

export default ({ colors }) => {
  const matchStatus = matchHasWinner =>
    matchHasWinner ? 'finished' : 'unfinished';
  const nodeHtmlClass = matchHasWinner =>
    matchHasWinner
      ? 'match-graph-node-finished'
      : 'match-graph-node-unfinished';
  const edgeStartColor = parentStatus =>
    parentStatus === 'finished' ? colors.primary : colors['grilla-pink'];
  const edgeEndColor = childStatus =>
    childStatus === 'finished' ? colors.primary : colors['grilla-blue'];
  const emptyName = '&ltempty&gt';

  const MatchesGraph = {
    graph: undefined,
    container: undefined,
    allParticipantDetails: [],
    canManageTournament: false,
    myself: undefined,
    containerId: undefined,
    numberOfZoomsToFit: 0,
    addNode(attrs) {
      const node = this.graph.addNode(attrs);
    },
    addEdge(attrs) {
      this.graph.addEdge(attrs);
    },
    zoomToCell(node) {
      this.graph.zoomTo(1.5);
      this.graph.centerCell(node, {
        animation: { duration: 200, easing: 'linear' }
      });
    },
    buildMatchNodeHtml({
      stage_id,
      match_id,
      starts_at,
      match_type,
      stage_round,
      stage_status,
      match_round,
      mp_details,
      tournament_status,
      is_resettable,
      match_label
    }) {
      const matchHasWinner = !!mp_details.find(({ rank }) => rank === 0);

      const showSetScoreInput = id =>
        id && this.canManageTournament && tournament_status == 'in_progress';

      const showMarkMatchWinnerButton = id =>
        this.canManageTournament &&
        tournament_status == 'in_progress' &&
        !matchHasWinner;

      const markMatchWinnerButton = id => {
        if (id) {
          return `
<div phx-click="mark-match-winner-clicked" phx-value-id="${id}" phx-target="${this.myself}" class="btn btn--primary p-0 h-full mx-2">
W
</div>
`;
        } else {
          return `
<div class="h-full mx-4">
</div>
`;
        }
      };

      const matchParticipantScore = (id, score, rank) => {
        const safeScore = score || '0';
        if (showSetScoreInput(id)) {
          const scoreInputId = `match-participant-score-input-${id}-input`;
          return `
<form id="match-participant-score-input-${id}-form" class="h-full" action="#" phx-change="set-match-participant-score" phx-target="${this.myself}">
  <input class="hidden" type="text" name="id" value=${id} />
  <input id="${scoreInputId}" inputmode="numeric" class="form-input h-full p-0 font-normal text-center border-primary w-10" phx-debounce="700" type="text" min="0" onClick="this.select();" name="score" value=${safeScore} />
</form>
`;
        } else {
          const scoreClass = id
            ? rank == 0
              ? 'match-graph-winner-score'
              : 'match-graph-participant-score'
            : 'hidden';

          return `
  <div class="${scoreClass}">
    ${safeScore}
  </div>
`;
        }
      };

      const emptyParticipantDetail = {
        id: null,
        match_id: match_id,
        tournament_participant_id: null,
        score: null,
        name: emptyName
      };

      const numberMpsPerMatch = 2;
      const numberEmptyMps =
        numberMpsPerMatch - Math.min(numberMpsPerMatch, mp_details.length);

      Array.from(Array(numberEmptyMps)).forEach(val =>
        mp_details.push(emptyParticipantDetail)
      );

      const participantDetailsHtml = mp_details
        .map(
          ({
            id,
            tournament_participant_id,
            name: nameOverride,
            score,
            rank
          }) => {
            const { name, logo_url } = this.allParticipantDetails.find(
              ({ id: participantId }) =>
                participantId === (tournament_participant_id || null)
            );
            const showNameOnly = [
              'scheduled',
              'registrations_open',
              'registrations_closed'
            ].includes(tournament_status);

            const showMpSwitcher =
              this.canManageTournament &&
              !this.debugMode &&
              !matchHasWinner &&
              match_round === 0 &&
              ((stage_round == 0 &&
                !['requires_tiebreaking', 'finished'].includes(stage_status)) ||
                (stage_round > 0 &&
                  tournament_status == 'in_progress' &&
                  !['requires_tiebreaking', 'finished'].includes(
                    stage_status
                  )));
            const showMarkScoreAndWinner = showMpSwitcher;

            const mpSwitcherOrName = () => {
              if (showMpSwitcher) {
                const participantOptions = this.allParticipantDetails.map(
                  ({ id: otherParticipantId, name: otherParticipantName }) => {
                    const selected =
                      otherParticipantId === tournament_participant_id
                        ? 'selected'
                        : '';
                    return `<option ${selected} value="${otherParticipantId}">${
                      otherParticipantName || emptyName
                    }</option>`;
                  }
                );
                return `
<form class="h-full w-full px-1" action="#" phx-change="switch-match-participant">
  <input class="hidden" type="text" name="stage-id" value=${stage_id} />
  <input class="hidden" type="text" name="match-id" value=${match_id} />
  <input class="hidden" type="text" name="mp-id" value=${id} />
<select id="match-participant-switcher-${id}-match-${match_id}" name="switch_match_participant[new_tp_id]" class="form-input p-1">
${participantOptions}
</select>
</form>
`;
              } else {
                return nameOverride || name || 'TBD';
              }
            };

            return `
<div class="${
              rank == 0
                ? 'match-graph-match-winner'
                : 'match-graph-match-participant'
            }">
  <div class="match-graph-participant-details ${
    id ? '' : 'match-graph-tbd-participant'
  }" >
    ${showMarkMatchWinnerButton(id) ? markMatchWinnerButton(id) : ''}
    <img src=${logo_url} alt="" class="match-graph-participant-logo">
    ${mpSwitcherOrName()}
  </div>
  ${matchParticipantScore(id, score, rank)}
</div>
`;
          }
        )
        .join('\n');

      const showMatchResetButton =
        this.canManageTournament &&
        tournament_status == 'in_progress' &&
        is_resettable;

      let node;
      const centralNode = document.createElement(`div`);
      centralNode.classList.add(nodeHtmlClass(matchHasWinner));
      if (matchHasWinner) {
        node = centralNode;
      } else {
        const innerNode = document.createElement(`div`);
        innerNode.id = `match-graph-node-${match_id}`;
        innerNode.classList.add('match-graph-node');
        centralNode.appendChild(innerNode);
        node = innerNode;
      }

      node.innerHTML = participantDetailsHtml;

      if (showMatchResetButton) {
        const resetMatchButton = document.createElement(`div`);
        resetMatchButton.id = `reset-match-button-${match_id}`;
        resetMatchButton.classList.add('reset-match-button');
        resetMatchButton.innerHTML = `
<div phx-click="reset-match-clicked" phx-value-id="${match_id}" phx-target="${this.myself}" title="Reset match" class="btn btn--primary-ghost p-0 text-2xl">
↺
</div>
`;
        node.appendChild(resetMatchButton);
      }
      const showMatchLabel = match_type === 'upper';

      if (showMatchLabel) {
        const wrapperNode = document.createElement(`div`);
        const matchLabelElement = document.createElement(`div`);
        wrapperNode.id = `match-graph-node-${match_id}-wrapper`;
        wrapperNode.classList.add('match-graph-node-wrapper');
        matchLabelElement.id = `match-graph-node-${match_id}-label`;
        matchLabelElement.classList.add('match-graph-node-label');
        matchLabelElement.innerHTML = match_label;
        wrapperNode.appendChild(matchLabelElement);
        wrapperNode.appendChild(centralNode);
        node = wrapperNode;
      } else {
        node = centralNode;
      }

      return node;
    },
    mounted() {
      const pushEventToComponent = (event, payload) => {
        this.pushEventTo(this.el, event, payload);
      };

      this.canManageTournament = this.el.dataset.canManageTournament;
      this.myself = this.el.dataset.myself;
      this.debugMode = !!this.el.dataset.debugMode;
      this.debugMode && console.log("You're in debug mode.");
      this.containerId = this.el.id;
      this.container = document.getElementById(this.containerId);
      this.graph = new Graph({
        async: true,
        container: this.container,
        mousewheel: {
          enabled: true,
          modifiers: ['ctrl', 'meta']
        },
        grid: {
          size: 10,
          visible: true,
          type: 'dot',
          args: {
            color: colors.gray['900'],
            thickness: 1
          }
        },
        background: {
          opacity: 1
        },
        interacting: this.debugMode,
        connecting: {
          router: 'orth'
        },
        infinite: true,
        panning: {
          enabled: true,
          eventTypes: ['leftMouseDown']
        }
      });
      for (let [parentStatus, childStatus] of [
        ['finished', 'finished'],
        ['finished', 'unfinished'],
        ['unfinished', 'finished'],
        ['unfinished', 'unfinished']
      ]) {
        Graph.registerEdge(
          `match-edge-${parentStatus}-to-${childStatus}`,
          {
            inherit: 'edge',
            markup: [
              {
                tagName: 'path',
                selector: 'fill'
              }
            ],
            attrs: {
              fill: {
                connection: true,
                strokeWidth: 1,
                strokeLinecap: 'round',
                fill: 'none',
                stroke: {
                  type: 'linearGradient',
                  stops: [
                    {
                      offset: '0%',
                      color: edgeStartColor(parentStatus)
                    },
                    {
                      offset: '100%',
                      color: edgeEndColor(childStatus)
                    }
                  ]
                }
              }
            }
          },
          true
        );
      }
      this.graph.on('node:dblclick', ({ node }) => {
        this.zoomToCell(node);
      });

      this.graph.on('render:done', () => {
        // only auto-fit twice - once isn't enough.
        if (this.numberOfZoomsToFit < 2) {
          this.numberOfZoomsToFit++;
          this.graph.zoomToFit();
        }
      });
      this.handleEvent('show_loading_message', ({ image_url }) => {
        this.addNode({
          id: 'loadingMessage',
          x: 200,
          y: 140,
          width: 500,
          height: 300,
          shape: 'html',
          html() {
            const element = document.createElement('div');
            element.classList.add('matches-graph-loading-message');
            element.classList.add('card');
            element.innerHTML = `
<div class="flex justify-center mb-6">
  <img src=${image_url} alt="" class="h-12">
</div>
<p class="text-center">
  Please wait. Building graph...
</p>
`;
            return element;
          }
        });
      });
      this.handleEvent('hide_loading_message', () => {
        this.graph.removeNode('loadingMessage');
      });
      this.handleEvent(
        'start_building_graph',
        ({ all_participant_details }) => {
          this.allParticipantDetails = all_participant_details;
          pushEventToComponent('start_building_graph', {});
        }
      );
      this.handleEvent(
        'add_edge',
        ({ edge, parent_has_winner, child_has_winner }) => {
          const parentStatus = matchStatus(parent_has_winner);
          const childStatus = matchStatus(child_has_winner);
          const shape = `match-edge-${parentStatus}-to-${childStatus}`;
          this.addEdge({ ...edge, shape: shape });
        }
      );
      this.handleEvent(
        'update_edge',
        ({ edge, parent_has_winner, child_has_winner }) => {
          const originalEdge = this.graph.getCellById(edge.id);
          if (originalEdge) {
            this.graph.removeCell(originalEdge);
            const parentStatus = matchStatus(parent_has_winner);
            const childStatus = matchStatus(child_has_winner);
            const shape = `match-edge-${parentStatus}-to-${childStatus}`;
            this.addEdge({ ...edge, shape: shape });
          }
        }
      );
      this.handleEvent(
        'add_logo_node',
        ({ x, y, width, height, image_url }) => {
          this.addNode({
            id: 'logo',
            x,
            y,
            width,
            height,
            shape: 'image',
            imageUrl: image_url
          });
        }
      );
      this.handleEvent('add_bracket_label', ({ x, y, width, height, type }) => {
        this.addNode({
          id: `${type}-bracket-label`,
          x,
          y,
          width,
          height,
          shape: 'html',
          html() {
            const element = document.createElement('div');
            element.classList.add('match-graph-bracket-label');
            element.innerHTML = `${type} Bracket`;
            return element;
          }
        });
      });
      this.handleEvent(
        'add_final_winner',
        ({ x, y, width, height, winner_details }) => {
          const allParticipantDetails = this.allParticipantDetails;
          this.addNode({
            id: 'finalWinner',
            x,
            y,
            width,
            height,
            shape: 'html',
            html() {
              const { tournament_participant_id } = winner_details;
              const { name, logo_url } = allParticipantDetails.find(
                ({ id: participantId }) =>
                  participantId === (tournament_participant_id || null)
              );
              const element = document.createElement('div');
              element.innerHTML = `
<div class="final-winner-logo-container">
  <img src=${logo_url} alt="" class="h-full">
</div>
<h2 class="final-winner-label">
  ${name} won!
</h2>
`;
              return element;
            }
          });
        }
      );
      this.handleEvent(
        'update_node',
        ({
          stage_id,
          match_id,
          starts_at,
          match_type,
          stage_round,
          stage_status,
          match_round,
          mp_details,
          is_resettable,
          tournament_status,
          skip_rebuilding_node_if_can_manage_tournament
        }) => {
          if (
            skip_rebuilding_node_if_can_manage_tournament &&
            this.canManageTournament
          )
            return;
          const matchNode = this.graph.getCellById(match_id);
          if (!matchNode) return;
          const matchLabelElement = document.getElementById(
            `match-graph-node-${match_id}-label`
          );
          const match_label = matchLabelElement
            ? matchLabelElement.innerText
            : '';
          matchNode.html = this.buildMatchNodeHtml({
            stage_id,
            match_id,
            starts_at,
            match_type,
            stage_round,
            stage_status,
            match_round,
            mp_details,
            tournament_status,
            is_resettable,
            match_label
          });
        }
      );
      this.handleEvent('zoom-in', () => {
        this.graph.zoom(zoomFactor);
      }),
        this.handleEvent('zoom-out', () => {
          this.graph.zoom(-zoomFactor);
        }),
        this.handleEvent('zoom-to-fit', () => {
          this.graph.zoomToFit();
        }),
        this.handleEvent(
          'add_node',
          ({
            stage_id,
            match_id,
            x,
            y,
            width,
            height,
            starts_at,
            match_type,
            stage_round,
            stage_status,
            match_round,
            mp_details,
            tournament_status,
            is_resettable,
            match_label
          }) => {
            this.addNode({
              id: match_id,
              x,
              y,
              width,
              height,
              shape: 'html',
              html: () =>
                this.buildMatchNodeHtml({
                  stage_id,
                  match_id,
                  starts_at,
                  match_type,
                  stage_round,
                  stage_status,
                  match_round,
                  mp_details,
                  tournament_status,
                  is_resettable,
                  match_label
                })
            });
          }
        );
    }
  };
  return { hooks: { MatchesGraph } };
};
