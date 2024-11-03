defmodule StridentWeb.FaqLive do
  @moduledoc false
  use StridentWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(:page_title, "FAQ")
    |> assign_cash_prize_states()
    |> assign_challenges_states()
    |> then(&{:ok, &1})
  end

  defp assign_cash_prize_states(socket) do
    states = [
      "Alabama",
      "Alaska",
      "Arizona",
      "Arkansas",
      "California",
      "Colorado",
      "Connecticut",
      "Delaware",
      "District of Columbia",
      "Florida",
      "Georgia",
      "Hawaii",
      "Idaho",
      "Illinois",
      "Indiana",
      "Iowa",
      "Kansas",
      "Kentucky",
      "Louisiana",
      "Maine",
      "Maryland",
      "Massachusetts",
      "Michigan",
      "Minnesota",
      "Mississippi",
      "Missouri",
      "Montana",
      "Nebraska",
      "Nevada",
      "New Hampshire",
      "New Jersey",
      "New Mexico",
      "New York",
      "North Carolina",
      "North Dakota",
      "Ohio",
      "Oklahoma",
      "Oregon",
      "Pennsylvania",
      "Rhode Island",
      "South Carolina",
      "South Dakota",
      "Tennessee",
      "Texas",
      "Utah",
      "Vermont",
      "Virginia",
      "Washington",
      "West Virginia",
      "Wisconsin",
      "Wyoming"
    ]

    assign(socket, :cash_prize_states, Enum.join(states, ", "))
  end

  defp assign_challenges_states(socket) do
    states = [
      "Alabama",
      "Alaska",
      "California",
      "Colorado",
      "Delaware",
      "Georgia",
      "Hawaii",
      "Idaho",
      "Illinois",
      "Iowa",
      "Kansas",
      "Kentucky",
      "Maine",
      "Massachusetts",
      "Michigan",
      "Minnesota",
      "Mississippi",
      "Missouri",
      "Nevada",
      "New Hampshire",
      "New York",
      "North Carolina",
      "North Dakota",
      "Ohio",
      "Oklahoma",
      "Oregon",
      "Pennsylvania",
      "Rhode Island",
      "Texas",
      "Vermont",
      "Virginia",
      "Washington",
      "West Virginia",
      "Wisconsin",
      "Wyoming",
      "District of Columbia"
    ]

    assign(socket, :challenges_states, Enum.join(states, ", "))
  end
end
