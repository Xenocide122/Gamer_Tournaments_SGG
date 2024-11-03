defmodule StridentWeb.Router do
  use StridentWeb, :router

  import StridentWeb.UserAuth
  import StridentWeb.WhitelistController
  alias StridentWeb.InitAssigns

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(Ueberauth)
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {StridentWeb.LayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_user)
    plug(StridentWeb.Plugs.AssignRemoteIp)
    plug(StridentWeb.Plugs.UserAgent)
    plug(StridentWeb.Plugs.BotDetector)
    plug(StridentWeb.Plugs.SegmentIdentify)
    plug(StridentWeb.Plugs.IpLocation)
    plug(StridentWeb.Plugs.ReturnTo)
    plug(StridentWeb.Plugs.IsUsingVpn)
    plug(StridentWeb.Plugs.ShowVPNBanner)
    plug(StridentWeb.Plugs.SetUsersGepographicRestrictions)
    plug(StridentWeb.Plugs.IsMobile)
    plug(StridentWeb.Plugs.SessionId)
    plug(StridentWeb.Plugs.BuildSession)
  end

  pipeline :health do
    plug(:accepts, ["html"])
    plug(:put_secure_browser_headers)
  end

  pipeline :graphql_api do
    plug(:accepts, ["json"])
    plug(:fetch_current_user_for_api)
    plug(StridentWeb.Plugs.AssignRemoteIp)
    plug(StridentWeb.Plugs.UserAgent)
    plug(StridentWeb.Plugs.BotDetector)
    plug(StridentWeb.Plugs.SegmentIdentify)
    plug(StridentWeb.Plugs.IpLocation)
    plug(StridentWeb.Plugs.ReturnTo)
    plug(StridentWeb.Plugs.IsUsingVpn)
    plug(StridentWeb.Plugs.ShowVPNBanner)
    plug(StridentWeb.Plugs.SetUsersGepographicRestrictions)
    plug(StridentWeb.Plugs.IsMobile)
    plug(StridentWeb.Plugs.LogGraphqlDocument)
    plug(StridentWeb.Plugs.BuildGraphqlContext)
  end

  scope "/", StridentWeb do
    pipe_through(:health)
    get("/sitemap.xml", SitemapController, :index)
  end

  scope "/sanity-check", StridentWeb do
    get("/are-all-nodes-connected", SanityCheckController, :are_all_nodes_connected)
  end

  if System.get_env("UNDER_CONSTRUCTION") do
    scope "/", StridentWeb do
      get("/", UnderConstructionController, :get)
      post("/", UnderConstructionController, :post)
    end
  else
    scope "/", StridentWeb do
      get("/game-truck", StrideRedirectController, :simple_redirect)
      get("/game-truck/confirmation", StrideRedirectController, :simple_redirect)
      get("/minecraft/confirmation", StrideRedirectController, :simple_redirect)
      get("/minecraft/explorers-club", StrideRedirectController, :simple_redirect)
      get("/minecraft/underwater-base-challenge", StrideRedirectController, :simple_redirect)
      get("/minecraft/educational-worlds", StrideRedirectController, :simple_redirect)
      get("/minecraft/minecraft-worlds-jamestown/", StrideRedirectController, :simple_redirect)
      get("/minecraft/minecraft-worlds-egypt/", StrideRedirectController, :simple_redirect)
      get("/minecraft/minecraft-worlds-rome/", StrideRedirectController, :simple_redirect)

      get(
        "/minecraft/minecraft-worlds-atomic-rescue/",
        StrideRedirectController,
        :simple_redirect
      )

      get(
        "/minecraft/minecraft-worlds-ocean-climate/",
        StrideRedirectController,
        :simple_redirect
      )

      get("/minecraft/minecraft-worlds-civil-war/", StrideRedirectController, :simple_redirect)

      get(
        "/minecraft/minecraft-worlds-library-league/",
        StrideRedirectController,
        :simple_redirect
      )

      get("/minecraft/minecraft_server/", StrideRedirectController, :simple_redirect)
      get("/minecraft/build_challenge", StrideRedirectController, :simple_redirect)
      get("/minecraft/bi-weekly-challenges", StrideRedirectController, :simple_redirect)
      get("/minecraft-build-challenge", StrideRedirectController, :simple_redirect)
      get("/minecraft-builds", StrideRedirectController, :simple_redirect)
      get("/minecraft/mini_games/clumsy_crew", StrideRedirectController, :simple_redirect)
      get("/minecraft/mini_games/block_battle", StrideRedirectController, :simple_redirect)
      get("/minecraft/mini_games", StrideRedirectController, :simple_redirect)
      get("/minecraft/support", StrideRedirectController, :simple_redirect)
      get("/minecraft", StrideRedirectController, :simple_redirect)
      get("/mysticat", StrideRedirectController, :simple_redirect)
      get("/legundo", StrideRedirectController, :simple_redirect)
      get("/gt_01", StrideRedirectController, :simple_redirect)
      get("/gt_02", StrideRedirectController, :simple_redirect)
      get("/gt_03", StrideRedirectController, :simple_redirect)
      get("/gt_04", StrideRedirectController, :simple_redirect)
      get("/gt_05", StrideRedirectController, :simple_redirect)
      get("/gt_06", StrideRedirectController, :simple_redirect)
    end

    scope "/", StridentWeb do
      pipe_through([:browser, :require_unconfirmed_user])
      live("/please-confirm-your-email", ConfirmEmailLive, :index)
    end

    scope "/", StridentWeb do
      pipe_through([:browser, :require_authenticated_user])
      post("/timezone/update", UserTimezoneController, :update)

      live_session :authenticated_user, on_mount: InitAssigns do
        get("/users/settings/confirm_email/:token", UserSettingsController, :confirm_email)
        live("/users/settings", UserSettingsLive, :edit)
        post("/users/settings", UserSettingsController, :update)
      end
    end

    scope "/", StridentWeb do
      pipe_through([:browser, :require_authenticated_confirmed_user])

      live_session :authenticated_confirmed_user, on_mount: InitAssigns do

        live("/giveaway", GiveawayLive.Index, :index, as: :giveaway_index)

        live("/teams/settings/:slug", TeamSettingsLive)

        live("/my-tournaments", MyTournamentsLive.Index, :index)
        live("/team/create", TeamRegistrationLive.New)
        live("/team/:slug/winnings", TeamWinningsLive.Show)
        live("/team/:slug/settings", TeamSettingsLive.Show)
        live("/team/:slug/rosters", TeamRostersLive.Show)
        live("/team/:slug/tournaments", TeamTournamentsLive.Show)

        live("/party/:id/members", PartyManagementLive.Index)
        live("/party/:id/payouts", PartyManagementLive.Show)

        live("/tournament/:slug/dashboard", TournamentDashboardLive)
        live("/t/:slug/stream", TournamentStreamLive)

        live("/t/:slug/invitations", TournamentInvitationsLive)
        live("/tournament/:slug/invitations", TournamentInvitationsLive)
        live("/tournament/:slug/settings", TournamentSettingsLive)
        live("/tournament/:slug/settings/:page", TournamentSettingsLive)
        live("/tournament/:slug/settings/basic-settings", TournamentSettingsLive)
        # live("/tournament/:slug/settings/match-settings", TournamentSettingsLive)
        live("/tournament/:slug/settings/stage-settings", TournamentSettingsLive)
        live("/tournament/:slug/settings/payment-info", TournamentSettingsLive)
        live("/tournament/:slug/settings/cancel-tournament", TournamentSettingsLive)
        live("/tournament/:slug/settings/brackets-structure", TournamentSettingsLive)

        live("/tournament/:id_or_slug/participants", TournamentPageLive.Show, :participants)

        live(
          "/tournament/:id_or_slug/bracket_and_seeding",
          TournamentPageLive.Show,
          :bracket_and_seeding
        )

        live(
          "/tournament/:id_or_slug/bracket_and_seeding/:stage",
          TournamentPageLive.Show,
          :bracket_and_seeding
        )

        live(
          "/tournament/:id_or_slug/bracket_and_seeding/:stage/:round",
          TournamentPageLive.Show,
          :bracket_and_seeding
        )

        live("/tournament/:slug/matches_and_results", MatchesAndResultsLive, :index,
          as: :tournament_matches_and_results
        )

        live("/tournament/:slug/matches_and_results/:stage", MatchesAndResultsLive, :index,
          as: :tournament_matches_and_results
        )

        live("/tournament/:slug/matches_and_results/:stage/:round", MatchesAndResultsLive, :index,
          as: :tournament_matches_and_results
        )

        live("/tournament/:slug/player-dashboard", PlayerDashboardLive, :index,
          as: :player_dashboard
        )

        live("/me/notifications", NotificationLive.NotificationLive, :index, as: :notifications)

        get(
          "/team/:slug/invitation/:invitation_token",
          TeamUserInvitationController,
          :accept_invitation
        )
      end

      get("/unimpersonate", ImpersonateUserController, :unimpersonate)
    end

    scope "/", StridentWeb do
      pipe_through([
        :browser,
        :require_authenticated_confirmed_user,
        :redirect_vpn_user,
        :redirect_unless_whitelisted
      ])

      live_session :check_vpn_location_verification,
        on_mount: [
          InitAssigns,
          {StridentWeb.Live.VpnSessionLive, :redirect_vpn_user},
          {StridentWeb.Live.InitWhitelist, :redirect_unless_whitelisted}
        ] do
        live("/tournament/:slug/participant/registration", TournamentRegistrationLive.Index)

        live(
          "/tournament/:slug/participant/registration/:invitation",
          TournamentRegistrationLive.Index
        )
      end
    end

    scope "/", StridentWeb do
      pipe_through(:browser)

      live_session :default, on_mount: InitAssigns do
        live("/", HomeLive)
        live("/coming-soon", ComingSoonLive)
        live("/play-now", PlayNowLive, :index, as: :play_now)
        live("/faq", FaqLive)
        live("/privacy-policy", LegalLive.PrivacyPolicy)
        live("/terms-of-service", LegalLive.TermsOfService)
        live("/fair-play-policy", LegalLive.FairplayPolicy)

        # live("/cookie-policy", LegalLive.CookiePolicy)
        live("/stylekit", StylekitLive)

        get("/oauth2/init/twitch", Oauth2Controllers.TwitchController, :init)
        get("/oauth2/callback/twitch", Oauth2Controllers.TwitchController, :callback)

        # get(
        # "/oauth2/native-callback/twitch",
        # Oauth2Controllers.TwitchController,
        # :native_callback
        # )

        get("/auth/:provider", Oauth2Controllers.AuthController, :request)
        get("/auth/:provider/callback", Oauth2Controllers.AuthController, :callback)

        delete("/users/log_out", UserSessionController, :delete)
        get("/users/confirm", UserConfirmationController, :new)
        post("/users/confirm", UserConfirmationController, :create)
        get("/users/confirm/:token", UserConfirmationController, :update)

        live("/user/:slug", UserLive.Show, :show, as: :user_show)
        live("/user/:slug/:type", UserLive.Show, :show, as: :user_type)
        live("/user/:slug/following", UserLive.Show, :show, as: :user_following)
        live("/user/:slug/followers", UserLive.Show, :show, as: :user_followers)

        live("/team/:slug", TeamProfileLive.Show)
        live("/team/:slug/rosters/:roster_slug", TeamProfileLive.Show)
        live("/team/:slug/:type", TeamProfileLive.Show, :show, as: :team_type)
        live("/team/:slug/followers", TeamProfileLive.Show, :show, as: :team_followers)

        live("/tournaments", TournamentsLive.Index, :index, as: :tournament_index)
        live("/tournament/:id_or_slug", TournamentPageLive.Show, :show, as: :tournament_show)
        live("/t/b/:slug", TournamentBracketAndSeedingLive.WebView, :index)
        live("/t/:id_or_slug", TournamentPageLive.Show, :show, as: :tournament_show_pretty)
        live("/t/:tournament_slug/contribution", TournamentContributionLive)

        live("/g/:vanity_url", TournamentPageLive.Show, :show, as: :tournament_show_vanity_url)

        live("/search", SearchLive)
        live("/search/:search_term", SearchLive)

        live("/community", CommunityLive.Index, :index, as: :community_index)

      end

      get(
        "/tournament/:slug/invitation/:action/:invitation_token",
        TournamentInvitationController,
        :invitation_response
      )
    end

    scope "/", StridentWeb do
      pipe_through([:browser, :ensure_current_user_is_staff])

      live_session :staff_user_create_tournament, on_mount: InitAssigns do
        live("/tournaments/create/", TournamentLive.Create.Index, :index, as: :create_tournament)

        live("/tournaments/create/:page", TournamentLive.Create.Index, :index,
          as: :create_tournament
        )
      end
    end

    scope "/admin", StridentWeb do
      pipe_through([:browser, :ensure_current_user_is_staff])

      live_session :staff_user, on_mount: InitAssigns do
        live("/prize-logic", PrizeLogicLive.Index, :index, as: :prize_logic)
        live("/home", AdminLive.Index, :index)
        live("/games", GamesLive.Index, :index)
        live("/games/:id/edit", GamesLive.Edit, :edit)
        live("/games/new", GamesLive.Create, :create)
        live("/tournament_cards", TournamentCardsLive.Index, :index)
        live("/tournament_cards/:id/edit", TournamentCardsLive.Edit, :edit)
        live("/tournament_cards/new", TournamentCardsLive.Create, :create)
        live("/homepage", HomepageLive.Index, :index)
        live("/genres/new", GenresLive.Create, :create)
        live("/genres/:id/edit", GenresLive.Edit, :edit)
        live("/features", AdminLive.Features.Index, :index)
        live("/features/:id/edit", AdminLive.Features.Edit, :edit)
        live("/features/new", AdminLive.Features.Create, :create)
        live("/cluster", ClusterLive.Index, :index)
        live("/horde", HordeLive.Index, :index)
        live("/users", AdminLive.User.Index, :index)
        live("/payouts", PayoutsLive.Index, :index)
        live("/dupe_emails", AdminLive.DupeEmails, :index)

        get("/impersonate", ImpersonateUserController, :impersonate)
      end
    end

    scope "/", StridentWeb do
      pipe_through([:browser, :redirect_if_user_is_authenticated])

      live_session :unauthenticated_user, on_mount: InitAssigns do
        live("/users/register", UserRegistrationLive)
        live("/users/log_in", UserLogInLive)
        post("/users/register", UserRegistrationController, :create)
        post("/users/log_in", UserSessionController, :create)
        get("/users/reset_password", UserResetPasswordController, :new)
        post("/users/reset_password", UserResetPasswordController, :create)
        get("/users/reset_password/:token", UserResetPasswordController, :edit)
        put("/users/reset_password/:token", UserResetPasswordController, :update)
      end
    end

    @absinthe_plug_opts [
      schema: StridentWeb.Schema,
      analyze_complexity: true,
      max_complexity: 1100
    ]

    # scope "/api" do
    #   pipe_through(:graphql_api)
    #   unless Mix.env() in [:prod] and is_nil(System.get_env("IS_STAGING")) do
    #     forward("/graphiql", Absinthe.Plug.GraphiQL, @absinthe_plug_opts)
    #   end
    #   forward("/", Absinthe.Plug, @absinthe_plug_opts)
    # end

    import Phoenix.LiveDashboard.Router

    scope "/" do
      if Mix.env() in [:prod] do
        pipe_through([:browser, :ensure_current_user_is_staff])
      else
        pipe_through(:browser)
      end

      live_dashboard("/live-dashboard", metrics: StridentWeb.Telemetry)
    end

    # Enables the Swoosh mailbox preview in development.
    #
    # Note that preview only shows emails that were sent by the same
    # node running the Phoenix server.
    if Mix.env() == :dev do
      scope "/dev" do
        pipe_through(:browser)

        forward("/mailbox", Plug.Swoosh.MailboxPreview)
      end

      scope "/dev" do
        pipe_through(:graphql_api)
        post("/image-uploads", StridentWeb.Dev.UploadImageController, :post_image)

        get(
          "/image-uploads/:type/:path/:image_name",
          StridentWeb.Dev.UploadImageController,
          :get_image
        )

        get("/image-uploads/:path/:image_name", StridentWeb.Dev.UploadImageController, :get_image)
      end
    end
  end
end
