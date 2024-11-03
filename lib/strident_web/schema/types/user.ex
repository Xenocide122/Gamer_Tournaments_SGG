defmodule StridentWeb.Schema.Types.User do
  @moduledoc false

  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  alias Strident.Accounts
  alias Strident.Accounts.UserFollower
  alias Strident.Schema.ResolutionEctoUtils
  alias Strident.UrlGeneration
  alias Strident.UserTournamentResults
  alias StridentWeb.Schema.DataloaderUtils

  @desc "A User within our system, meant for private consumption."
  object :user do
    field(:id, :string)
    field(:display_name, :string)
    field(:slug, :string)
    field(:is_pro, :boolean)

    field :can_play, non_null(:boolean) do
      resolve(fn _, _, resolution ->
        {:ok, Map.get(resolution.context, :can_play, false)}
      end)
    end

    field :can_stake, non_null(:boolean) do
      resolve(fn _, _, resolution ->
        {:ok, Map.get(resolution.context, :can_stake, false)}
      end)
    end

    field :can_wager, non_null(:boolean) do
      resolve(fn _, _, resolution ->
        {:ok, Map.get(resolution.context, :can_wager, false)}
      end)
    end

    field :avatar_url, :string do
      resolve(fn _, resolution ->
        (resolution.source.avatar_url || Accounts.return_default_avatar())
        |> UrlGeneration.absolute_path()
        |> then(&{:ok, &1})
      end)
    end

    field(:state, non_null(:us_state_code))
    field(:is_legal_adult, non_null(:boolean))
    field(:locale, non_null(:string))
    field(:timezone, non_null(:string))
    field(:password_credential, :password_credential)
    field(:favorite_games, non_null(list_of(non_null(:game))), resolve: dataloader(:data))

    field :email, :string do
      resolve(fn _, _, resolution ->
        with %{
               context: %{
                 loader: loader,
                 current_user: %{id: current_user_id, is_staff: is_staff}
               },
               source: source
             } <- resolution,
             true <- !!is_staff || current_user_id == source.id do
          Accounts.credential_preloads()
          |> Enum.reduce_while(nil, fn credential_preload, _ ->
            case DataloaderUtils.get_via_loader(loader, credential_preload, source) do
              nil -> {:cont, nil}
              %{email: email} -> {:halt, email}
            end
          end)
        else
          _ -> nil
        end
        |> then(&{:ok, &1})
      end)
    end

    field :tournaments_playing_in, :list_of_tournaments do
      resolve(fn user_profile, _, resolution ->
        opts = ResolutionEctoUtils.query_arguments(resolution)
        {:ok, UserTournamentResults.user_tournaments(user_profile, opts)}
      end)
    end

    field(
      :device_notification_settings,
      non_null(list_of(non_null(:device_notification_setting))),
      resolve: dataloader(:data)
    )
  end

  @desc "A public User profile, meant for public consumption."
  object :user_profile do
    field(:id, :string)
    field(:display_name, :string)
    field(:slug, :string)
    field(:avatar_url, :string)
    field(:banner_url, :string)
    field(:is_pro, :boolean)
    field(:is_tournament_organizer, :boolean)
    field(:is_caster, :boolean)
    field(:is_graphic_designer, :boolean)
    field(:is_producer, :boolean)
    field(:bio, :string)
    field(:real_name, :string)
    field(:location, :string)
    field(:birthday, :date)
    field(:battlefy_profile, :string)
    field(:challonge_profile, :string)
    field(:smashgg_profile, :string)

    field(:favorite_games, list_of(non_null(:game)))
    field(:social_media_links, list_of(non_null(:social_media_link)))

    field :followers, :list_of_user_follow_cards do
      resolve(fn _, _, resolution ->
        DataloaderUtils.paginated_assoc(resolution, [:followers])
      end)
    end

    field :following, :list_of_user_follow_cards do
      resolve(fn _, _, resolution ->
        DataloaderUtils.paginated_assoc(resolution, [:following])
      end)
    end

    field(:following_teams, list_of(non_null(:team_follow_card)))
    field(:photos, list_of(non_null(:photo)))

    field :tournament_results, :list_of_user_tournament_results do
      resolve(fn user_profile, _, resolution ->
        opts =
          resolution
          |> ResolutionEctoUtils.query_arguments()
          |> Keyword.merge(filter_tournament_statuses: [:finished])

        {:ok, UserTournamentResults.user_tournament_results(user_profile, opts)}
      end)
    end

    field :placements, :list_of_placements do
      resolve(fn _, _, resolution ->
        DataloaderUtils.paginated_assoc(resolution, [:placements])
      end)
    end

    field :current_user_follows, :boolean do
      resolve(fn parent, _args, resolution ->
        case resolution.context do
          %{current_user: %{id: current_user_id}, loader: loader} ->
            user_follower =
              loader
              |> Dataloader.load(
                :data,
                {:one, UserFollower, filter: %{user_id: parent.id}},
                follower_id: current_user_id
              )
              |> Dataloader.run()
              |> Dataloader.get(
                :data,
                {:one, UserFollower, filter: %{user_id: parent.id}},
                follower_id: current_user_id
              )

            {:ok, not is_nil(user_follower)}

          _ ->
            {:ok, false}
        end
      end)
    end
  end

  @desc "A condensed user struct to represent a list of followers or followed users"
  object :user_follow_card do
    field(:id, :string)
    field(:display_name, :string)
    field(:slug, :string)
    field(:avatar_url, :string)
    field(:current_user_follows, :boolean)
  end

  object :list_of_user_follow_cards do
    field(:entries, non_null(list_of(non_null(:user_follow_card))))
    field(:page_number, :integer)
    field(:page_size, :integer)
    field(:total_pages, :integer)
    field(:total_entries, :integer)
  end

  @desc "A condensed team struct to represent a list of followed teams"
  object :team_follow_card do
    field(:id, :string)
    field(:name, :string)
    field(:slug, :string)
    field(:logo_url, :string)
    field(:current_user_follows, :boolean)
  end

  @desc "Social Media Link"
  object :social_media_link do
    field(:id, :id)
    field(:handle, :string)
    field(:brand, non_null(:social_media_brand))
    field(:url, :string)
  end

  @desc "User uploaded photo for graphic designers"
  object :photo do
    field(:link, :string)
    field(:name, :string)
  end

  enum :social_media_brand do
    value(:facebook)
    value(:instagram)
    value(:twitter)
    value(:youtubechannel)
    value(:youtube)
    value(:twitch)
    value(:discordapp)
    value(:discord)
    value(:steamid)
    value(:steamprofile)
    value(:reddit)
    value(:lastfm)
    value(:other)
  end

  object :user_tournament_result do
    field(:tournament, non_null(:tournament))
    field(:rank, :integer)
    field(:tied_ranks, non_null(list_of(:integer)))
  end

  object :list_of_user_tournament_results do
    field(:entries, list_of(non_null(:user_tournament_result)))
    field(:page_number, :integer)
    field(:page_size, :integer)
    field(:total_pages, :integer)
    field(:total_entries, :integer)
  end

  @desc "Device Notification Setting for user"
  object :device_notification_setting do
    field(:id, :string)
    field(:key, :device_notification_setting_type)
    field(:value, :string)
  end

  enum :device_notification_setting_type do
    value(:apple)
    value(:android)
  end
end
