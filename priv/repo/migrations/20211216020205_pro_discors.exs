defmodule Strident.Repo.Migrations.ProDiscors do
  use Ecto.Migration

  def change do
    alter table(:pros) do
      add :discord_account, :string
    end
  end
end
