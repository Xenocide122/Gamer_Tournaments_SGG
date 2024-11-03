defmodule Strident.Repo.Migrations.AlterTwitchCredentialsAddDeletedAt do
  use Ecto.Migration

  def change do
    alter table(:twitch_credentials) do
      modify :email, :string, null: true
      add :deleted_at, :utc_datetime
    end

    drop index(:twitch_credentials, [:email], name: :twitch_credentials_email_index)

    create unique_index(:twitch_credentials, [:email],
             where: "deleted_at is null",
             name: :twitch_credentials_non_deleted_email_unique_index
           )
  end
end
