defmodule Strident.Repo.Migrations.AddSlugColumnToProUserAndTeam do
  use Ecto.Migration

  def change do
    rename table(:pros), :profile_url, to: :slug

    alter table(:users) do
      add :slug, :string, null: true
    end

    execute "UPDATE users set slug=display_name;"

    alter table(:users) do
      modify :slug, :string, null: false
    end

    alter table(:teams) do
      add :slug, :string, null: true
    end

    execute "UPDATE teams set slug=name;"

    alter table(:teams) do
      modify :slug, :string, null: false
    end
  end
end
