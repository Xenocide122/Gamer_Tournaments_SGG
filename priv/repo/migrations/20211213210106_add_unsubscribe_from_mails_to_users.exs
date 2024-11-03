defmodule Strident.Repo.Migrations.AddUnsubscribeFromMailsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :unsubscribe_from_emails, :boolean, default: false
    end
  end
end
