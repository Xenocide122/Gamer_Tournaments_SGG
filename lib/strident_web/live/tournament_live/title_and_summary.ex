defmodule StridentWeb.TournamentLive.TitleAndSummary do
  @moduledoc """
  Editable tournament title and summary
  """
  use StridentWeb, :live_component
  alias Phoenix.LiveView.JS

  attr(:can_manage_tournament, :boolean, required: true)
  attr(:changeset, :any, required: true)
  attr(:id, :string, required: true)
  attr(:summary, :any, required: true)
  attr(:title, :string, required: true)

  def render(assigns) do
    ~H"""
    <div id={@id} class="flex flex-col justify-start gap-2">
      <h1 class="font-bold"><%= @title %></h1>

      <.form
        :let={f}
        :if={@can_manage_tournament}
        id="tournament-summary-form"
        for={@changeset}
        phx-change="validate-tournament-summary"
        phx-submit="save-tournament-summary"
        class="hidden"
      >
        <div class="flex flex-col gap-2">
          <.form_textarea
            form={f}
            field={:summary}
            class="bg-transparent lg:w-128"
            rows="5"
            placeholder="Write a summary about this tournament"
            phx-debounce={1000}
          />
          <.form_feedback form={f} field={:summary} />

          <.button
            id="tournament-summary-save-button"
            button_type={:primary}
            class="rounded"
            phx-click={
              JS.toggle(to: "#tournament-summary")
              |> JS.toggle(to: "#tournament-summary-form", display: "flex")
              |> JS.toggle(to: "#edit-summary-button")
            }
          >
            Save
          </.button>
        </div>
      </.form>

      <div id="tournament-summary" class="lg:w-1/2">
        <%= @summary %>
      </div>
      <p
        :if={@can_manage_tournament}
        id="edit-summary-button"
        class="cursor-pointer text-primary"
        phx-click={
          JS.toggle(to: "#tournament-summary")
          |> JS.toggle(to: "#tournament-summary-form")
          |> JS.toggle(to: "#edit-summary-button")
        }
      >
        Edit
      </p>
    </div>
    """
  end
end

defmodule StridentWeb.TournamentLive.TitleAndSummary.Handler do
  @moduledoc """
  For the parent LiveView to `use` in order to handle TitleAndSummary events.

  The parent LiveView socket needs these assigns:

  -  `:tournament`
  -  `:can_manage_tournament`.
  """
  alias Strident.Tournaments
  alias Strident.Tournaments.Tournament

  defmacro __using__(_opts) do
    quote do
      @impl true
      def handle_event("validate-tournament-summary", %{"tournament" => params}, socket) do
        %{tournament: tournament, can_manage_tournament: can_manage_tournament} = socket.assigns

        if can_manage_tournament do
          socket
          |> assign(:changeset, Tournaments.change_tournament(tournament, params))
          |> then(&{:noreply, &1})
        else
          put_flash(socket, :error, "You don't have permission for this action")
        end
      end

      @impl true
      def handle_event("save-tournament-summary", %{"tournament" => params}, socket) do
        %{tournament: tournament, can_manage_tournament: can_manage_tournament} = socket.assigns

        if can_manage_tournament do
          case Tournaments.update_tournament(tournament, params) do
            {:ok, tournament} ->
              %{summary: summary} = tournament

              socket
              |> update(:tournament, &%Tournament{&1 | summary: summary})
              |> put_flash(:info, "Tournament Summary updated sucessfully")

            {:error, changeset} ->
              put_string_or_changeset_error_in_flash(socket, changeset)
          end
        else
          put_flash(socket, :error, "You don't have permission for this action")
        end
        |> then(&{:noreply, &1})
      end
    end
  end
end
