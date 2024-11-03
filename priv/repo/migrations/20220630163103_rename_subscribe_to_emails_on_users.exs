defmodule Strident.Repo.Migrations.RenameSubscribeToEmailsOnUsers do
  use Ecto.Migration

  def change do
    rename table(:users), :unsubscribe_from_emails, to: :subscribe_to_emails
  end
end
