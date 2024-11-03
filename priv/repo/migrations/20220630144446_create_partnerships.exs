defmodule Strident.Repo.Migrations.CreatePartnerships do
  use Ecto.Migration

  def change do
    create table(:partnerships, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :text
      add :email, :text
      add :about, :text

      add :partnership_role_id,
          references(:partnership_roles, on_delete: :nothing, type: :binary_id)

      add :social_media_urls, {:array, :text}

      timestamps()
    end

    create index(:partnerships, [:partnership_role_id])
  end
end
