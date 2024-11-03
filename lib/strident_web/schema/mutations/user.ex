defmodule StridentWeb.Schema.Mutations.User do
  @moduledoc false

  use Absinthe.Schema.Notation

  alias StridentWeb.Resolvers.UserResolver
  alias StridentWeb.Schema.Middleware

  input_object :login_input do
    field(:email, non_null(:string))
    field(:password, non_null(:string))
  end

  object :login_result do
    field(:errors, list_of(non_null(:input_error)))
    field(:user, :user)
    field(:token, :string)

    @desc """
    Used for OAuth login.
    Indicates if the returned user is a "new user",
    i.e. if the user was created by this login action.

    This field will be NULL for password-credential logins.
    If this field is NULL, it tells us nothing.
    """
    field(:is_new_user, :boolean)
  end

  input_object :registration_input do
    field(:email, non_null(:string))
    field(:password, non_null(:string))
    field(:display_name, non_null(:string))
    field(:state, :us_state_code)
    field(:is_legal_adult, :boolean)
    field(:locale, non_null(:string))
    field(:timezone, non_null(:string))
  end

  input_object :device_notification_setting_input do
    field(:key, non_null(:device_notification_setting_type))
    field(:value, non_null(:string))
  end

  object :registration_validations do
    field(:email, list_of(non_null(:form_validation)))
    field(:password, list_of(non_null(:form_validation)))
    field(:display_name, list_of(non_null(:form_validation)))
    field(:state, list_of(non_null(:form_validation)))
    field(:is_legal_adult, list_of(non_null(:form_validation)))
    field(:locale, list_of(non_null(:form_validation)))
    field(:timezone, list_of(non_null(:form_validation)))
  end

  object :registration_result do
    field(:errors, list_of(non_null(:input_error)))
    field(:token, :string)
    field(:user, :user)
  end

  object :update_my_favorite_games_result do
    field(:errors, list_of(non_null(:input_error)))
    field(:user, :user)
  end

  object :social_media_link_result do
    field(:errors, list_of(non_null(:input_error)))
    field(:social_media_link, :social_media_link)
  end

  object :follow_result do
    field(:errors, list_of(non_null(:input_error)))
    field(:follower, :follower)
  end

  object :follower do
    field(:user_id, :string)
    field(:follower_id, :string)
    field(:follows, :boolean)
  end

  object :accout_result do
    field(:errors, list_of(non_null(:input_error)))
    field(:user, :user)
  end

  object :notification_result do
    field(:errors, list_of(non_null(:input_error)))
    field(:notification, :notification)
  end

  object :user_mutations do
    @desc "Login to your user account"
    field :login, :login_result do
      arg(:input, non_null(:login_input))
      resolve(&UserResolver.login/3)
      middleware(&add_current_user_to_resolution_context/2)
    end

    @desc "Register with an email and password"
    field :register, :registration_result do
      arg(:input, non_null(:registration_input))
      resolve(&UserResolver.register/3)
      middleware(&add_current_user_to_resolution_context/2)
    end

    @desc """
    Bulk replace current user's favorite games
    """
    field :update_my_favorite_games, :update_my_favorite_games_result do
      arg(:game_ids, non_null(list_of(non_null(:id))))
      middleware(Middleware.Authorize, [:auth])
      resolve(&UserResolver.update_my_favorite_games/3)
    end

    @desc "Follow or unfollow a user"
    field :set_follow_user, :follow_result do
      arg(:user_id, non_null(:id))
      arg(:set_follow, non_null(:boolean))
      middleware(Middleware.Authorize, [:auth])
      resolve(&UserResolver.set_follow_user/3)
    end

    @desc """
    Create a social media link
    """
    field :create_social_media_link, :social_media_link_result do
      arg(:user_input, non_null(:string))
      middleware(Middleware.Authorize, [:auth])
      resolve(&UserResolver.create_social_media_link/3)
    end

    @desc """
    Update a social media link, provided the social media link belongs to the current user
    """
    field :update_social_media_link, :social_media_link_result do
      arg(:social_media_link_id, non_null(:id))
      arg(:user_input, non_null(:string))
      middleware(Middleware.Authorize, [:auth])
      resolve(&UserResolver.update_social_media_link/3)
    end

    @desc """
    Delete a social media link, provided the social media link belongs to the current user
    """
    field :delete_social_media_link, :social_media_link_result do
      arg(:social_media_link_id, non_null(:id))
      middleware(Middleware.Authorize, [:auth])
      resolve(&UserResolver.update_social_media_link/3)
    end

    @desc """
    Deletes User's account.
    """
    field :delete_account, :accout_result do
      middleware(Middleware.Authorize, [:auth])
      resolve(&UserResolver.delete_account/3)
    end

    @desc """
    Creates new User device notification token.
    """
    field :create_device_notification_setting, :accout_result do
      arg(:input_device_notification_setting, non_null(:device_notification_setting_input))
      middleware(Middleware.Authorize, [:auth])
      resolve(&UserResolver.create_device_notification_setting/3)
    end

    @desc """
    Set Notification as read.
    """
    field :update_notification_to_read, :notification_result do
      arg(:notification_id, non_null(:string))
      middleware(Middleware.Authorize, [:auth])
      resolve(&UserResolver.update_notification_to_read/3)
    end
  end

  defp add_current_user_to_resolution_context(resolution, _) do
    with %{value: %{user: user}} <- resolution do
      %{resolution | context: Map.put(resolution.context, :current_user, user)}
    end
  end
end
