defmodule StridentWeb.Schema do
  @moduledoc false
  use Absinthe.Schema
  use StridentWeb.Schema.Directives.Filters
  use StridentWeb.Schema.Directives.Sorting
  alias StridentWeb.Schema.DataloaderUtils
  alias StridentWeb.Schema.Middleware
  alias StridentWeb.Schema.Mutations
  alias StridentWeb.Schema.Queries
  alias StridentWeb.Schema.Types

  import_types(Absinthe.Type.Custom)
  import_types(Types.Auth)
  import_types(Types.Custom.JSON)
  import_types(Types.Custom.Money)
  import_types(Types.Custom.Sorting)
  import_types(Types.Error)
  import_types(Types.FormValidation)
  import_types(Types.Pagination)
  import_types(Types.Placement)
  import_types(Types.UsState)
  import_types(Types.User)
  import_types(Types.Game)
  import_types(Types.Match)
  import_types(Types.MatchParticipant)
  import_types(Types.MatchReport)
  import_types(Types.Notification)
  import_types(Types.Party)
  import_types(Types.Stage)
  import_types(Types.Team)
  import_types(Types.Tournament)
  import_types(Types.TournamentInvitation)
  import_types(Types.TournamentParticipant)

  def middleware(middleware, field, object) do
    middleware
    |> then(&[Middleware.MaxQueryDepth | &1])
    |> apply(:errors, field, object)
  end

  defp apply(middleware, :errors, _field, %{identifier: identifier})
       when identifier in [:mutation] do
    # use the errors middleware last
    middleware ++ [Middleware.MoveErrorsToValue]
  end

  defp apply(middleware, :errors, _field, _) do
    middleware
  end

  def context(ctx) do
    Dataloader.new()
    |> Dataloader.add_source(:data, DataloaderUtils.data())
    |> then(&Map.put(ctx, :loader, &1))
  end

  def plugins do
    [Middleware.AuthorizedIntrospection, Absinthe.Middleware.Dataloader] ++
      Absinthe.Plugin.defaults()
  end

  import_types(Queries.UsState)
  import_types(Queries.User)
  import_types(Queries.Game)
  import_types(Queries.Match)
  import_types(Queries.Tournament)
  import_types(Queries.Twitch)

  query do
    import_fields(:game_queries)
    import_fields(:match_queries)
    import_fields(:tournament_queries)
    import_fields(:twitch_queries)
    import_fields(:us_state_queries)
    import_fields(:user_queries)
  end

  import_types(Mutations.Apple)
  import_types(Mutations.BulkUpdateMatchParticipants)
  import_types(Mutations.Discord)
  import_types(Mutations.MatchReport)
  import_types(Mutations.UpdateMatchParticipant)
  import_types(Mutations.UpdateTournamentStatus)
  import_types(Mutations.Twitch)
  import_types(Mutations.User)
  import_types(Mutations.TournamentRegistration)
  import_types(Mutations.PartyInvitation)

  mutation do
    import_fields(:apple_mutations)
    import_fields(:discord_mutations)
    import_fields(:match_report_mutations)
    import_fields(:twitch_mutations)
    import_fields(:update_tournament_status_mutation)
    import_fields(:update_match_participant_mutation)
    import_fields(:bulk_update_match_participants_mutation)
    import_fields(:user_mutations)
    import_fields(:tournament_registration_mutations)
    import_fields(:party_invitation_mutations)
  end
end
