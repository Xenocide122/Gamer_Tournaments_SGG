defmodule Strident.Repo.Migrations.BackfillStages.Stage do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "stages" do
    field(:tournament_id, :string)
    field(:type, :string)
    timestamps()
  end
end

defmodule Strident.Repo.Migrations.BackfillStages do
  @moduledoc """
  Backfilling stages as per
  https://fly.io/phoenix-files/backfilling-data/
  """
  use Ecto.Migration
  import Ecto.Query
  alias Strident.Repo.Migrations.BackfillStages.Stage

  @disable_ddl_transaction true
  @disable_migration_lock true
  @batch_size 1000
  @throttle_ms 100
  # we disable credo for next line since we don't want to alias our NaiveDateTime Extension
  @now NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

  def up do
    throttle_change_in_batches(&page_query/1, &do_change/1)
  end

  def down do
    execute("DELETE from stages")
  end

  def do_change(entries) do
    {_number_updated, nil} = repo().insert_all(Stage, entries, log: :info)
    List.last(entries).tournament_id
  end

  def page_query(nil) do
    from(
      t in "tournaments",
      select: %{
        tournament_id: t.id,
        type: "single_elimination",
        inserted_at: @now,
        updated_at: @now
      },
      order_by: [asc: t.id],
      limit: @batch_size
    )
  end

  def page_query(last_id) do
    from(
      t in "tournaments",
      select: %{
        tournament_id: t.id,
        type: "single_elimination",
        inserted_at: @now,
        updated_at: @now
      },
      where: t.id > ^last_id,
      order_by: [asc: t.id],
      limit: @batch_size
    )
  end

  defp throttle_change_in_batches(query_fun, change_fun, last_pos \\ nil)

  defp throttle_change_in_batches(query_fun, change_fun, last_pos) do
    case repo().all(query_fun.(last_pos), log: :info, timeout: :infinity) do
      [] ->
        :ok

      ids ->
        next_page = change_fun.(List.flatten(ids))
        Process.sleep(@throttle_ms)
        throttle_change_in_batches(query_fun, change_fun, next_page)
    end
  end
end
