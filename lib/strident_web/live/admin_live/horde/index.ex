defmodule StridentWeb.HordeLive.Index do
  @moduledoc false
  use StridentWeb, :live_view
  alias Strident.HordeAdmin
  alias StridentWeb.AdminLive.Components.Menus

  @regions %{
    "ams" => "Amsterdam, Netherlands      ✓",
    "arn" => "Stockholm, Sweden",
    "bog" => "Bogotá, Colombia",
    "bos" => "Boston, Massachusetts (US)",
    "cdg" => "Paris, France               ✓",
    "den" => "Denver, Colorado (US)",
    "dfw" => "Dallas, Texas (US)          ✓",
    "ewr" => "Secaucus, NJ (US)",
    "fra" => "Frankfurt, Germany          ✓",
    "gdl" => "Guadalajara, Mexico",
    "gig" => "Rio de Janeiro, Brazil",
    "gru" => "Sao Paulo, Brazil",
    "hkg" => "Hong Kong, Hong Kong        ✓",
    "iad" => "Ashburn, Virginia (US)      ✓",
    "jnb" => "Johannesburg, South Africa",
    "lax" => "Los Angeles, California (US)✓",
    "lhr" => "London, United Kingdom      ✓",
    "maa" => "Chennai (Madras), India     ✓",
    "mad" => "Madrid, Spain",
    "mia" => "Miami, Florida (US)",
    "nrt" => "Tokyo, Japan                ✓",
    "ord" => "Chicago, Illinois (US)      ✓",
    "otp" => "Bucharest, Romania",
    "qro" => "Querétaro, Mexico",
    "scl" => "Santiago, Chile             ✓",
    "sea" => "Seattle, Washington (US)    ✓",
    "sin" => "Singapore, Singapore        ✓",
    "sjc" => "San Jose, California (US)   ✓",
    "syd" => "Sydney, Australia           ✓",
    "waw" => "Warsaw, Poland",
    "yul" => "Montreal, Canada",
    "yyz" => "Toronto, Canada             ✓"
  }

  @init_regions Enum.reduce(@regions, %{}, fn {code, desc}, acc ->
                  region_details = %{desc: desc, selected: true}
                  Map.put(acc, code, region_details)
                end)

  def mount(_params, _session, socket) do
    socket
    |> assign(:regions, @init_regions)
    |> assign_horde()
    |> then(&{:ok, &1})
  end

  def handle_event("click-region-code", %{"region-code" => region_code}, socket) do
    socket
    |> update(:regions, fn regions ->
      Map.update!(regions, region_code, fn region_details ->
        Map.update!(region_details, :selected, &(not &1))
      end)
    end)
    |> assign_horde()
    |> then(&{:noreply, &1})
  end

  defp assign_horde(socket) do
    %{regions: regions} = socket.assigns

    horde =
      regions
      |> Enum.filter(fn {_, %{selected: selected}} -> selected end)
      |> Enum.map(&elem(&1, 0))
      |> HordeAdmin.gimme_horde()

    assign(socket, :horde, horde)
  end
end
