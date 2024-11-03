defmodule Strident.Repo.Migrations.CreatePartnershipRoles do
  use Ecto.Migration

  def change do
    create table(:partnership_roles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :text

      timestamps()
    end

    create unique_index(:partnership_roles, [:name])
  end
end
