defmodule StridentWeb.CheckInLive do
  @moduledoc false
  use StridentWeb, :live_view
  alias Strident.Extension.DateTime
  alias Strident.Extension.NaiveDateTime
  alias Strident.Tournaments

  @impl true
  def render(assigns) do
    ~H"""
    <.socket_suspense show_inner_block={@is_connected}>
      <h4 class="mb-4">Participant Check In</h4>

      <p class="text-grey-light">
        Please check into the tournament using the button below. Check in opens 30 minutes prior to match start.
      </p>

      <div class="flex flex-col items-center justify-center mt-8">
        <div :if={not is_nil(@participant) and not @participant.checked_in}>
          <h4 :if={@allow_to_check_in?}>Check in closes in:</h4>
          <h4 :if={not @allow_to_check_in?}>Check in opens in:</h4>

          <.card colored={true} class="!rounded-lg" inner_class="!bg-blackish !rounded-lg">
            <div class="flex items-center justify-center h-24 text-white w-80 md:w-128 md:h-28">
              <.svg icon={:stopwatch} width="32" height="40" class="mr-2 md:h-14 md:w-12 fill-white" />
              <div class="text-4xl font-display md:text-7xl">
                <span
                  id={"countdown-to-check-in-match-#{@participant.id}"}
                  phx-update="ignore"
                  phx-hook="Countdown"
                  data-end_date={
                    if(@allow_to_check_in?, do: @time_to_check_in, else: @time_before_check_in_allowed)
                  }
                >
                </span>
              </div>
            </div>
          </.card>
        </div>

        <h4 :if={!!@participant and @participant.checked_in}>You're checked in!</h4>

        <.form
          :let={f}
          :if={@allow_to_check_in? and not @participant.checked_in}
          id={"check-in-participant-#{@participant.id}"}
          for={@form}
          phx-change="check-in-match"
          class="my-4 text-xl"
        >
          <div class="flex justify-end">
            <div class="flex items-center mb-2 mr-4">
              <div class="flex items-center justify-center flex-shrink-0 w-6 h-6 mr-2 bg-transparent border-2 rounded-md border-primary">
                <%= checkbox(f, :check_in,
                  class: "opacity-0 absolute",
                  checked: @check_in_checkbox
                ) %>
                <.svg
                  icon={:solid_check}
                  class="hidden w-4 h-4 transition pointer-events-none fill-primary"
                />
              </div>

              <div class={if(@check_in_checkbox, do: "text-primary")}>I'm here</div>
            </div>
          </div>
        </.form>

        <.button
          id={"check-in-button-#{@participant.id}"}
          button_type={:primary}
          class={if(not @allow_to_check_in? or @participant.checked_in, do: "mt-4")}
          disabled={disable_button?(@allow_to_check_in?, @participant, @check_in_checkbox)}
          phx-click="check-in-participant"
        >
          Check In
        </.button>

        <p :if={!!@error_checking_in} class="text-secondary"><%= @error_checking_in %></p>
      </div>
    </.socket_suspense>
    """
  end

  @impl true
  def mount(:not_mounted_at_router, session, socket) do
    %{
      "timezone" => timezone,
      "locale" => locale,
      "can_stake" => can_stake,
      "can_play" => can_play,
      "can_wager" => can_wager,
      "is_using_vpn" => is_using_vpn,
      "show_vpn_banner" => show_vpn_banner,
      "check_timezone" => check_timezone
    } = session

    socket
    |> assign_current_user_from_session_token(session)
    |> assign(:timezone, timezone)
    |> assign(:locale, locale)
    |> assign(:can_stake, can_stake)
    |> assign(:can_play, can_play)
    |> assign(:can_wager, can_wager)
    |> assign(:is_using_vpn, is_using_vpn)
    |> assign(:show_vpn_banner, show_vpn_banner)
    |> assign(:check_timezone, check_timezone)
    |> assign(:form, to_form(%{}, as: :participant))
    |> do_mount(%{}, session)
  end

  def mount(params, session, socket) do
    do_mount(socket, params, session)
  end

  defp do_mount(socket, _params, session) do
    is_connected = connected?(socket)

    %{"participant_id" => participant_id, "tournament_starts_at" => tournament_starts_at} =
      session

    participant =
      Tournaments.get_tournament_participant_with_preloads!(participant_id, players: [])

    socket
    |> assign(:error_checking_in, nil)
    |> assign(:participant, participant)
    |> assign(:tournament_starts_at, tournament_starts_at)
    |> assign(:check_in_checkbox, false)
    |> assign(:allow_to_check_in?, true)
    |> assign(:is_connected, is_connected)
    |> assign_time_before_check_in_allowed()
    |> assign_time_to_check_in()
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("check-in-participant", _params, socket) do
    %{assigns: %{participant: participant, current_user: current_user}} = socket

    with true <- is_current_user_allowed_to_check_in_on_match?(participant, current_user),
         {:ok, _tournament_participant} <- Tournaments.check_in_participant(participant) do
      socket
      |> update(:participant, &%{&1 | checked_in: true})
      |> assign(:check_in_checkbox, false)
      |> then(&{:noreply, &1})
    else
      _ ->
        socket
        |> assign(:error_checking_in, "You can't check-in")
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event("check-in-match", %{"participant" => params}, socket) do
    socket
    |> then(fn socket ->
      case params do
        %{"check_in" => "true"} -> assign(socket, :check_in_checkbox, true)
        %{"check_in" => "false"} -> assign(socket, :check_in_checkbox, false)
      end
    end)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info(:check_in_allowed, socket) do
    socket
    |> assign_time_before_check_in_allowed()
    |> assign_time_to_check_in()
    |> then(&{:noreply, &1})
  end

  def assign_time_before_check_in_allowed(socket) do
    %{tournament_starts_at: starts_at, timezone: timezone} = socket.assigns
    shift_start_time = Timex.shift(starts_at, minutes: -30)

    time =
      if Timex.is_valid_timezone?(timezone) do
        timezone = Timex.Timezone.get(timezone, Timex.now())

        shift_start_time
        |> DateTime.from_naive!("Etc/UTC")
        |> Timex.Timezone.convert(timezone)
      else
        shift_start_time
      end

    now_time =
      if Timex.is_valid_timezone?(timezone) do
        timezone = Timex.Timezone.get(timezone, Timex.now())

        NaiveDateTime.utc_now()
        |> DateTime.from_naive!("Etc/UTC")
        |> Timex.Timezone.convert(timezone)
      else
        NaiveDateTime.utc_now()
      end

    if Timex.compare(now_time, time) == -1 and connected?(socket) do
      send_time_to_refresh = Timex.diff(shift_start_time, now_time, :milliseconds)
      Process.send_after(self(), :check_in_allowed, send_time_to_refresh)
    end

    socket
    |> assign(:time_before_check_in_allowed, time)
    |> assign(:allow_to_check_in?, Timex.compare(now_time, time) > 0)
  end

  def assign_time_to_check_in(socket) do
    %{tournament_starts_at: starts_at, timezone: timezone} = socket.assigns

    time =
      if Timex.is_valid_timezone?(timezone) do
        timezone = Timex.Timezone.get(timezone, Timex.now())

        starts_at
        |> Timex.shift(minutes: 5)
        |> DateTime.from_naive!("Etc/UTC")
        |> Timex.Timezone.convert(timezone)
      else
        Timex.shift(starts_at, minutes: 5)
      end

    assign(socket, :time_to_check_in, time)
  end

  def is_current_user_allowed_to_check_in_on_match?(participant, current_user) do
    Enum.any?(participant.players, &(&1.user_id == current_user.id))
  end

  def disable_button?(allow_to_check_in?, participant, check_in_checkbox) do
    not allow_to_check_in? or (not participant.checked_in and not check_in_checkbox) or
      participant.checked_in
  end
end
