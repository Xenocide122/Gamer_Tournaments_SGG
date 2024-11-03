defmodule Strident.Repo.Migrations.AddDisplayNameToUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :display_name, :string, null: true
    end

    execute("""
    UPDATE users as u
    SET display_name=pro.twitch_handle
    FROM pros pro
    WHERE pro.user_id = u.id
    """)

    execute("""
    UPDATE users as u
    SET display_name=COALESCE(u.display_name, (regexp_split_to_array(pc.email, '[@]'))[1])
    FROM password_credentials pc
    WHERE pc.user_id = u.id
    """)

    execute("""
    UPDATE users as u
    SET display_name=COALESCE(u.display_name, (regexp_split_to_array(tc.email, '[@]'))[1])
    FROM twitch_credentials tc
    WHERE tc.user_id = u.id
    """)

    alter table(:users) do
      modify :display_name, :string, null: false
    end

    create index(
             :users,
             ["regexp_split_to_array(trim(both '-' from lower(display_name)), '[-]+')"],
             name: :display_name_uniqueness_index,
             unique: true
           )
  end

  def down do
    alter table(:users) do
      remove :display_name
    end
  end
end
