defmodule Strident.Repo.Migrations.AddAddressFieldsToTournament do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :address, :string
      add :city, :string
      add :state, :string
      add :postal_code, :string
    end
  end
end
