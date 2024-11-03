defmodule Strident.Repo.Migrations.RemoveRequiredStartsAtFiledOnMatches do
  use Ecto.Migration

  def change do
    alter table(:matches) do
      modify :starts_at, :naive_datetime, default: nil, null: true
    end
  end
end
