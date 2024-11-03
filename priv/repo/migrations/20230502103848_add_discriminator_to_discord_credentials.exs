defmodule Strident.Repo.Local.Migrations.AddDiscriminatorToDiscordCredentials do
  use Ecto.Migration

  def change do
    alter table(:discord_credentials) do
      add :discriminator, :string, null: true
    end
  end
end
