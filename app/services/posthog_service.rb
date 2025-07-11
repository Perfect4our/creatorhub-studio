class PosthogService
  include HTTParty
  
  BASE_URL = 'https://app.posthog.com'
  
  class << self
    # Track server-side events to PostHog
    def track_event(user_id:, event:, properties: {}, user_properties: {})
      return false unless posthog_configured?
      
      payload = {
        api_key: api_key,
        event: event,
        distinct_id: user_id.to_s,
        properties: default_properties.merge(properties),
        timestamp: Time.current.iso8601
      }
      
      # Add user properties if provided (for identification)
      if user_properties.any?
        payload[:set] = user_properties
      end
      
      begin
        response = HTTParty.post(
          "#{BASE_URL}/capture/",
          body: payload.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => 'CreatorHub Studio Rails Backend'
          },
          timeout: 2
        )
        
        log_request(event, response)
        response.success?
      rescue => e
        Rails.logger.error "PostHog tracking failed: #{e.message}"
        false
      end
    end
    
    # Identify a user with properties
    def identify_user(user_id:, properties: {})
      return false unless posthog_configured?
      
      payload = {
        api_key: api_key,
        event: '$identify',
        distinct_id: user_id.to_s,
        set: default_user_properties.merge(properties),
        timestamp: Time.current.iso8601
      }
      
      begin
        response = HTTParty.post(
          "#{BASE_URL}/capture/",
          body: payload.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => 'CreatorHub Studio Rails Backend'
          },
          timeout: 2
        )
        
        log_request('$identify', response)
        response.success?
      rescue => e
        Rails.logger.error "PostHog user identification failed: #{e.message}"
        false
      end
    end
    
    # Track user signup (critical event)
    def track_signup(user:, source: nil)
      track_event(
        user_id: user.id,
        event: 'user_signup_backend',
        properties: {
          email: user.email,
          signup_source: source,
          has_permanent_subscription: user.has_permanent_subscription?,
          platform: 'web',
          environment: Rails.env,
          server_tracked: true
        },
        user_properties: {
          email: user.email,
          signup_date: user.created_at.strftime('%Y-%m-%d'),
          user_role: user.admin? ? 'admin' : 'user'
        }
      )
    end
    
    # Track subscription events (critical event)
    def track_subscription(user:, event_type:, plan_name: nil, amount: nil, currency: 'usd')
      track_event(
        user_id: user.id,
        event: "subscription_#{event_type}_backend",
        properties: {
          email: user.email,
          plan_name: plan_name,
          amount_cents: amount,
          currency: currency,
          stripe_customer_id: user.stripe_customer_id,
          environment: Rails.env,
          server_tracked: true
        }
      )
    end
    
    # Track platform connection (critical event)
    def track_platform_connection(user:, platform:, connection_type: 'basic', success: true)
      track_event(
        user_id: user.id,
        event: 'platform_connection_backend',
        properties: {
          email: user.email,
          platform: platform,
          connection_type: connection_type,
          success: success,
          total_platforms: user.subscriptions.count,
          environment: Rails.env,
          server_tracked: true
        }
      )
    end
    
    # Track platform disconnection
    def track_platform_disconnection(user:, platform:)
      track_event(
        user_id: user.id,
        event: 'platform_disconnection_backend',
        properties: {
          email: user.email,
          platform: platform,
          remaining_platforms: user.subscriptions.count - 1,
          environment: Rails.env,
          server_tracked: true
        }
      )
    end
    
    # Track subscription cancellation (critical event)
    def track_cancellation(user:, reason: nil)
      track_event(
        user_id: user.id,
        event: 'subscription_cancelled_backend',
        properties: {
          email: user.email,
          cancellation_reason: reason,
          had_platforms_connected: user.subscriptions.any?,
          platform_count: user.subscriptions.count,
          stripe_customer_id: user.stripe_customer_id,
          environment: Rails.env,
          server_tracked: true
        }
      )
    end
    
    # Track billing portal access
    def track_billing_access(user:, source: 'unknown')
      track_event(
        user_id: user.id,
        event: 'billing_portal_accessed_backend',
        properties: {
          email: user.email,
          source: source,
          subscription_status: user.stripe_subscribed? ? 'active' : 'inactive',
          environment: Rails.env,
          server_tracked: true
        }
      )
    end

    # Get user's session recordings
    def get_user_recordings(user_id:, limit: 10)
      return [] unless posthog_configured? && secret_key.present?

      begin
        response = HTTParty.get(
          "#{BASE_URL}/api/projects/#{project_id}/session_recordings",
          headers: {
            'Authorization' => "Bearer #{secret_key}",
            'Content-Type' => 'application/json'
          },
          query: {
            distinct_id: user_id.to_s,
            limit: limit,
            order: '-start_time'
          },
          timeout: 5
        )

        if response.success?
          recordings = response.parsed_response['results'] || []
          Rails.logger.info "PostHog: Retrieved #{recordings.length} recordings for user #{user_id}"
          recordings
        else
          Rails.logger.error "PostHog: Failed to get recordings - #{response.code}: #{response.body}"
          []
        end
      rescue => e
        Rails.logger.error "PostHog recordings fetch failed: #{e.message}"
        []
      end
    end

    # Delete specific recording
    def delete_recording(recording_id:)
      return false unless posthog_configured? && secret_key.present?

      begin
        response = HTTParty.delete(
          "#{BASE_URL}/api/projects/#{project_id}/session_recordings/#{recording_id}",
          headers: {
            'Authorization' => "Bearer #{secret_key}",
            'Content-Type' => 'application/json'
          },
          timeout: 5
        )

        if response.success?
          Rails.logger.info "PostHog: Successfully deleted recording #{recording_id}"
          true
        else
          Rails.logger.error "PostHog: Failed to delete recording #{recording_id} - #{response.code}: #{response.body}"
          false
        end
      rescue => e
        Rails.logger.error "PostHog recording deletion failed: #{e.message}"
        false
      end
    end

    # Manage user recordings (keep only 5 most recent)
    def manage_user_recordings(user_id:, max_recordings: 5)
      return false unless posthog_configured?

      recordings = get_user_recordings(user_id: user_id, limit: 20)
      
      if recordings.length > max_recordings
        recordings_to_delete = recordings[max_recordings..-1]
        
        recordings_to_delete.each do |recording|
          recording_id = recording['id']
          if delete_recording(recording_id: recording_id)
            Rails.logger.info "PostHog: Deleted old recording #{recording_id} for user #{user_id}"
          end
        end
        
        Rails.logger.info "PostHog: Cleaned up #{recordings_to_delete.length} old recordings for user #{user_id}"
        true
      else
        Rails.logger.info "PostHog: User #{user_id} has #{recordings.length} recordings, no cleanup needed"
        false
      end
    end

    # Track recording events
    def track_recording_event(user_id:, event_type:, recording_data: {})
      track_event(
        user_id: user_id,
        event: "recording_#{event_type}",
        properties: {
          recording_management: true,
          environment: Rails.env,
          server_tracked: true,
          **recording_data
        }
      )
    end
    
    private
    
    def posthog_configured?
      api_key.present?
    end
    
    def api_key
      @api_key ||= Rails.application.credentials.dig(:posthog, :public_key) ||
                   Rails.application.credentials.dig(:posthog, :api_key) || 
                   Rails.application.credentials.posthog_api_key ||
                   ENV['POSTHOG_API_KEY']
    end
    
    def secret_key
      @secret_key ||= Rails.application.credentials.dig(:posthog, :secret_key) || 
                      Rails.application.credentials.posthog_secret_key ||
                      ENV['POSTHOG_SECRET_KEY']
    end

    def project_id
      @project_id ||= Rails.application.credentials.dig(:posthog, :project_id) || 
                      Rails.application.credentials.posthog_project_id ||
                      ENV['POSTHOG_PROJECT_ID']
    end
    
    def default_properties
      {
        source: 'backend',
        environment: Rails.env,
        server_timestamp: Time.current.iso8601,
        application: 'CreatorHub Studio'
      }
    end
    
    def default_user_properties
      {
        environment: Rails.env,
        platform: 'web',
        last_seen_backend: Time.current.iso8601
      }
    end
    
    def log_request(event, response)
      if Rails.env.development?
        if response.success?
          Rails.logger.info "📊 PostHog Backend: #{event} tracked successfully"
        else
          Rails.logger.error "❌ PostHog Backend: #{event} failed - #{response.code}: #{response.body}"
        end
      end
    end
  end
end 