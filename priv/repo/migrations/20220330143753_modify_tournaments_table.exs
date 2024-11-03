defmodule Strident.Repo.Migrations.ModifyTournamentsTable do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :website, :string
      add :contact_email, :string
      add :show_contact_email, :boolean, default: false
    end
  end
end
