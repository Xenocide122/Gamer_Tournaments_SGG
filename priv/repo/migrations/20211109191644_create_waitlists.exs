defmodule Strident.Repo.Migrations.CreateWaitlists do
  use Ecto.Migration

  def change do
    create table(:waitlists, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :text

      timestamps()
    end

    create unique_index(:waitlists, [:email])
  end
end
