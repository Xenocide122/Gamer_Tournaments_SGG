defmodule Strident.Repo.Local.Migrations.AddTitleToDraftForms do
  use Ecto.Migration

  def change do
    alter table(:draft_forms) do
      add :title, :string, null: true, size: 1023
    end
  end
end
