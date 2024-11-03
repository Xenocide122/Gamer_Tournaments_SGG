defmodule StridentWeb.ClusterLive.Index do
  @moduledoc false
  use StridentWeb, :live_view
  alias StridentWeb.AdminLive.Components.Menus

  def mount(_params, _session, socket) do
    nodes = list_nodes()

    region_codes_by_node =
      Enum.reduce(nodes, %{}, fn node, acc ->
        value =
          case Fly.RPC.region(node) do
            :error -> nil
            {:ok, region_code} -> region_code
          end

        Map.put(acc, node, value)
      end)

    node_details =
      for node <- nodes do
        region = Map.get(region_codes_by_node, node)
        %{id: node, region: region}
      end

    socket
    |> assign(:node_details, node_details)
    |> then(&{:ok, &1})
  end

  if Application.compile_env(:strident, :env) == :prod do
    defp list_nodes, do: Node.list(:known)
  else
    @mock_nodes [
      :"grilla-staging@fdaa:0:ac7d:a7b:67:6d7c:7455:2",
      :"grilla-staging@fdaa:0:ac7d:a7b:8566:852a:9d6:2",
      :"grilla-staging@fdaa:0:ac7d:a7b:2cc3:f90d:3b9:2"
    ]
    defp list_nodes, do: @mock_nodes
  end
end
