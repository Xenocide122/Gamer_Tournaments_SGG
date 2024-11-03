defmodule Strident.Repo.Migrations.AddIsProToUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :is_pro, :boolean, null: true, default: false
    end

    execute("update users set is_pro=false")

    alter table(:users) do
      modify :is_pro, :boolean, null: false, default: false
    end
  end

  def down do
    alter table(:users) do
      remove :is_pro
    end
  end
end
