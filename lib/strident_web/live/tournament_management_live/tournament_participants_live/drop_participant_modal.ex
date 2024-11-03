defmodule StridentWeb.TournamentParticipantsLive.Components.DropParticipantModal do
  @moduledoc false
  use StridentWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"are-you-sure-you-want-to-drop-#{@id}"} class="z-50">
      <.modal_small id={@id} on_confirm={hide_modal(@id)}>
        <div class="flex flex-col items-center justify-center text-center">
          <img class="mb-2 rounded-b max-h-20" src="/images/font-awesome/alert.svg" alt="alert" />

          <h2 class="text-secondary">Warning</h2>
          <p class="text-xl">
            This will delete all your match data (scores, winners, challenges, etc.).
          </p>
          <p class="px-8 mb-8 text-xs text-grey-light">
            <span :if={not @free_tournament and @registerd_participant} class="text-xs text-secondary">
              Refunding their entry fee will withdraw those funds from the prize pool as well.
            </span>
            <span class="text-xs text-secondary">
              Are you sure you want to drop participant <%= @participant_name %> and regenerate matches?
            </span>
          </p>
        </div>
        <:cancel>
          <button class="btn border-grey-light text-grey-light" phx-click={hide_modal(@id)}>
            Go Back
          </button>
        </:cancel>
        <:confirm>
          <.button
            id={"drop-participant-button-#{@participant_id}"}
            class="text-white btn border-primary btn--primary-ghost"
            phx-click="drop-and-refund"
            phx-value-participant={@participant_id}
          >
            <%= if not @free_tournament and @registerd_participant,
              do: "I'm sure.",
              else: "I'm sure." %>
          </.button>
        </:confirm>
      </.modal_small>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    %{
      id: id,
      participant_id: participant_id,
      participant_name: participant_name,
      participant_status: participant_status,
      free_tournament: free_tournament,
      can_manage_tournament: can_manage_tournament
    } = assigns

    socket
    |> copy_parent_assigns(assigns)
    |> assign(:id, id)
    |> assign(:participant_id, participant_id)
    |> assign(:participant_name, participant_name)
    |> assign(:participant_status, participant_status)
    |> assign(:can_manage_tournament, can_manage_tournament)
    |> assign(:free_tournament, free_tournament)
    |> assign(:registerd_participant, participant_status in [:staking, :confirmed])
    |> then(&{:ok, &1})
  end
end
