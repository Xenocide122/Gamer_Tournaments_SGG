defmodule Strident.Repo.Migrations.CreateParties do
  use Ecto.Migration

  def change do
    create table(:parties, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false

      timestamps()
    end
  end
end
