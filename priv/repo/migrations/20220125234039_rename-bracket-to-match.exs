defmodule :"Elixir.Strident.Repo.Migrations.Rename-bracket-to-match" do
  use Ecto.Migration

  def change do
    execute(
      """
      ALTER INDEX brackets_pkey RENAME TO matches_pkey;
      """,
      """
      ALTER INDEX matches_pkey RENAME TO brackets_pkey;
      """
    )

    execute(
      """
      ALTER INDEX brackets_tournament_id_index RENAME TO matches_tournament_id_index;
      """,
      """
      ALTER INDEX matches_tournament_id_index RENAME TO brackets_tournament_id_index;
      """
    )

    execute(
      """
      ALTER INDEX bracket_participants_pkey RENAME TO match_participants_pkey;
      """,
      """
      ALTER INDEX match_participants_pkey RENAME TO bracket_participants_pkey;
      """
    )

    execute(
      """
      ALTER INDEX bracket_participants_bracket_id_index RENAME TO match_participants_match_id_index;
      """,
      """
      ALTER INDEX match_participants_match_id_index RENAME TO bracket_participants_bracket_id_index;
      """
    )

    execute(
      """
      ALTER INDEX bracket_edges_pkey RENAME TO match_edges_pkey;
      """,
      """
      ALTER INDEX match_edges_pkey RENAME TO bracket_edges_pkey;
      """
    )

    execute(
      """
      ALTER INDEX bracket_edges_child_id_parent_id_index RENAME TO match_edges_child_id_parent_id_index;
      """,
      """
      ALTER INDEX match_edges_child_id_parent_id_index RENAME TO bracket_edges_child_id_parent_id_index;
      """
    )

    execute(
      """
      ALTER INDEX bracket_edges_parent_id_index RENAME TO match_edges_parent_id_index;
      """,
      """
      ALTER INDEX match_edges_parent_id_index RENAME TO bracket_edges_parent_id_index;
      """
    )

    execute(
      """
      ALTER INDEX bracket_edges_child_id_index RENAME TO match_edges_child_id_index;
      """,
      """
      ALTER INDEX match_edges_child_id_index RENAME TO bracket_edges_child_id_index;
      """
    )

    rename table(:brackets), to: table(:matches)

    rename table(:bracket_edges), to: table(:match_edges)

    rename table(:bracket_participants), :bracket_id, to: :match_id
    rename table(:bracket_participants), to: table(:match_participants)
  end
end
