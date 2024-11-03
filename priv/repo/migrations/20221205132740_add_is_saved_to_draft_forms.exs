defmodule Strident.Repo.Local.Migrations.AddIsSavedToDraftForms do
  use Ecto.Migration

  def change do
    alter table(:draft_forms) do
      add :is_saved, :boolean, null: true
    end
  end
end
