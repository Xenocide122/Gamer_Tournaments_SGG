defmodule Strident.Repo.Migrations.AlterDisplayNameAndSlugNullableWhenDeletedOnUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :display_name, :string, null: true
      modify :slug, :string, null: true
    end

    drop index(:users, [:slug], name: :users_slug_index)

    create unique_index(:users, [:display_name],
             where: "deleted_at is null",
             name: :users_non_deleted_display_name_unique_index
           )

    create unique_index(:users, [:slug],
             where: "deleted_at is null",
             name: :users_non_deleted_slug_unique_index
           )
  end
end
