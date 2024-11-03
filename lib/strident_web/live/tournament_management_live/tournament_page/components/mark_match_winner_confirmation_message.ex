defmodule StridentWeb.TournamentPageLive.Components.MarkMatchWinnerConfirmationMessage do
  @moduledoc false
  use Phoenix.Component

  attr(:winner_name, :string, required: true)
  attr(:scores, :list, required: true)

  def mark_match_winner_confirmation_message(assigns) do
    ~H"""
    <div>
      <div class="mb-10 text-2xl text-center">
        Are you sure you want to mark "<%= @winner_name %>" as the winner?
      </div>
      <div class="mb-10 text-xl text-center">
        <div class="grid grid-cols-2 gap-x-4">
          <div class="col-span-2 mb-2 text-center border-b-2 border-grey-dark">
            Current scores:
          </div>
          <%= for score <- @scores do %>
            <div class="text-right text-grey-light">
              <%= score.name %>:
            </div>
            <div class="font-bold text-left">
              <%= score.score || "0" %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
