defmodule StridentWeb.TournamentLive.Create.PageNavButtons do
  @moduledoc """
  The "back/next" bottom buttons element, for navigating from page to page.
  """
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    socket
    |> then(&{:ok, &1})
  end

  @impl true
  def update(
        %{
          changeset: %{changes: changes},
          current_page: current_page
        },
        socket
      ) do
    {next_label, next_event} =
      case current_page do
        :payment ->
          {"Create Tournament", "create_tournament"}

        _ ->
          {"Next", "next"}
      end

    next_disabled =
      case Map.get(changes, current_page) do
        %{valid?: valid?} -> not valid?
        _ -> false
      end

    # next_disabled = if disable_verification_btn, do: true, else: next_disabled

    socket
    |> assign(:current_page, current_page)
    |> assign(:next_label, next_label)
    |> assign(:next_event, next_event)
    |> assign(:next_disabled, next_disabled)
    |> assign(
      :button_alignment,
      if(current_page == :tournament_type, do: "justify-center", else: "justify-between")
    )
    |> assign(
      :button_xPadding,
      if(current_page == :tournament_type, do: "md:px-24", else: "md:px-8")
    )
    |> then(&{:ok, &1})
  end
end
