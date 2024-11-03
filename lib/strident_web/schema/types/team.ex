defmodule StridentWeb.Schema.Types.Team do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Strident.Accounts
  alias Strident.Teams.Team
  alias Strident.UrlGeneration
  alias StridentWeb.Schema.DataloaderUtils

  object :team do
    field(:id, non_null(:string))
    field(:name, non_null(:string))

    field :email, :string do
      resolve(fn _, _, resolution ->
        with %{
               context: %{
                 loader: loader,
                 current_user: %{id: current_user_id, is_staff: is_staff}
               },
               source: source
             } <- resolution,
             true <- !!is_staff || is_member?(current_user_id, source, loader) do
          resolution.source.email
        else
          _ -> nil
        end
        |> then(&{:ok, &1})
      end)
    end

    field(:slug, non_null(:string))

    field :logo_url, :string do
      resolve(fn _, resolution ->
        (resolution.source.logo_url || Accounts.return_default_avatar())
        |> UrlGeneration.absolute_path()
        |> then(&{:ok, &1})
      end)
    end

    field(:description, :string)
    field(:banner_url, :string)
    field(:team_performance_history_image_url, :string)
  end

  defp is_member?(nil, _source, _loader), do: false

  defp is_member?(user_id, %Team{} = team, loader) do
    members = DataloaderUtils.get_via_loader(loader, :team_members, team)
    Enum.any?(members, &(&1.user_id == user_id))
  end
end
