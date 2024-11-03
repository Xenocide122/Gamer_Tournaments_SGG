defmodule Strident.Repo.Migrations.AddTimezoneLocaleToUser do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :locale, :string, null: true
      add :timezone, :string, null: true
    end

    execute("""
    update users set locale = 'en-US'
    """)

    execute("""
    update users set timezone = 'America/New_York'
    """)

    alter table(:users) do
      modify :locale, :string, null: false
      modify :timezone, :string, null: false
    end
  end

  def down do
    alter table(:users) do
      remove :locale
      remove :timezone
    end
  end
end
