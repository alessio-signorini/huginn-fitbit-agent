module Agents
  class FitbitAgent < Agent
    require 'oauth2'

    include FormConfigurable

    default_schedule 'every_1h'
    cannot_receive_events!
    can_dry_run!

    description <<-MD
      Create events from Fitbit activities

      OAUTHv2 client and secret can be specified in the configuration of the
        agent or globally using `ENV['FITBIT_OAUTH2_CLIENT']` and
        `ENV['FITBIT_OAUTH2_SECRET']`.

      The agent will remember some (`loopback`=50) activities so it can update
        them instead of creating new ones.

      Refer to [this page](https://dev.fitbit.com/build/reference/web-api/activity/#get-activity-logs-list)
        for a list of properties of the events created.

      After the agent is created go into its description to complete the OAUTHv2
        flow and authorize it to read your Fitbit data.
    MD

    form_configurable :scope
    form_configurable :lookback
    form_configurable :oauth2_client
    form_configurable :oauth2_secret

    def default_options
      {
        'lookback'      => 50,
        'scope'         => 'activity heartrate location nutrition profile settings sleep social weight'
      }
    end

    def validate_options
      unless options['lookback'].present? && options['lookback'].to_i > 0
        errors.add(:base, ":lookback needs to be a number greater than 0")
      end

      unless oauth2_client_string.present? && oauth2_client_string.match(/^[A-Z0-9]+$/)
        errors.add(:base, "ENV['FITBIT_OAUTH2_CLIENT'] or :oauth2_client need to be defined")
      end

      unless oauth2_secret_string.present? && oauth2_secret_string.match(/^\w+$/)
        errors.add(:base, "ENV['FITBIT_OAUTH2_SECRET'] or :oauth2_secret config need to be defined")
      end
    end


    after_initialize :initialize_memory
    def initialize_memory
      memory['seen'] ||= []
    end


    def working?
      memory['oauth2_token'].present? && memory['not_working'].nil?
      # Implement me! Maybe one of these next two lines would be a good fit?
      # checked_without_error?
      # received_event_without_error?
    end

    def check
      response = get_activities_list()
        return not_working! unless response.response.success?

      memory.delete('not_working')

      response.parsed['activities'].each do |activity|
        if seen_before?(activity)
          update_existing_event(activity)
        else
          create_new_event(activity)
        end
      end
    end

#    def receive(incoming_events)
#    end

    def receive_web_request(params, method, format)
      if params[:secret] == 'oauth2_callback'
        oauth2_get_token(params[:code])
        return [redirect_back, 200, 'text/html']
      end

      ["not found", 404, 'text/plain']
    end


    def view_url
      file = File.dirname(__FILE__) + '/../../views/_show.html.erb'
      return {:inline => File.read(file)}
    end


    def oauth2_callback_url
      "http://localhost:3000/users/#{user_id}/web_requests/#{id}/oauth2_callback"
    end

    private


    def oauth2_client_string
      ENV['FITBIT_OAUTH2_CLIENT'] || interpolated['oauth2_client']
    end


    def oauth2_secret_string
      ENV['FITBIT_OAUTH2_SECRET'] || interpolated['oauth2_secret']
    end



    def oauth2_client
      OAuth2::Client.new(oauth2_client_string,oauth2_secret_string,
        :site           => 'https://api.fitbit.com',
        :authorize_url  => '/oauth2/authorize',
        :token_url      => '/oauth2/token',
        :auth_scheme    => :basic_auth
      )
    end

    def oauth2_token
      if memory['oauth2_token'].present?
        return OAuth2::AccessToken.from_hash(oauth2_client, memory['oauth2_token'])
      else
        OAuth2::AccessToken.new(oauth2_client, 'unknown',
          :refresh_token  => interpolated['oauth2_refresh_token'],
          :expires_at     => 0
        )
      end
    end


    def oauth2_token_refresh!
      memory['oauth2_token'] = oauth2_token.refresh!.to_hash
      log("Refreshed access_token - #{memory['oauth2_token'].to_json}")
    end


    def get_activities_list(from_date=Date.today.to_s)
      url = '/1/user/-/activities/list.json'

      oauth2_token_refresh! if oauth2_token.expired?

      oauth2_token.get(url, :params => {
        :limit      => 20,
        :offset     => 0,
        :sort       => :asc,
        :afterDate  => from_date
      })
    end

    def not_working!
      memory['not_working'] = Time.now
      return false
    end


    def remember!(event)
      purge_memory_if_necessary!

      memory['seen'].push({
        'logId'     => event.payload['logId'],
        'event_id'  => event.id
      })

      log("New Activity (#{event.payload['logId']}), created Event(#{event.id})",
        :outbound_event => event
      )
    end


    def purge_memory_if_necessary!
      memory['seen'].shift if memory['seen'].length > options['lookback'].to_i
    end


    def get_old_event_id(payload)
      if x = memory['seen'].select{|x| x['logId'] == payload['logId']}.try(:first)
        return x['event_id']
      end
    end


    def seen_before?(payload)
      get_old_event_id(payload).present?
    end


    def update_existing_event(payload)
      event_id = get_old_event_id(payload)

      event = Event.find(event_id)
      event.payload = payload

      log("Existing Activity (#{payload['logId']}), updating Event(#{event.id})",
        :outbound_event => event
      )

      return create_event(event)
    end


    def create_new_event(payload)
      event = create_event(:payload => payload)
      remember!(event)
    end


    def oauth2_get_token(code)
      token = oauth2_client.get_token(
        :code         => code,
        :grant_type   => :authorization_code,
        :redirect_uri => oauth2_callback_url
      )

      memory['oauth2_token'] = token.to_hash

      log("OAUTH2 Token saved - #{token.to_hash.to_json}")
    end


    def redirect_back
      "<html><head><meta http-equiv='refresh' content='0; url=http://localhost:3000/agents/#{id}'/></head></html>"
    end

  end
end
