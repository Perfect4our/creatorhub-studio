class ManagePosthogRecordingsJob < ApplicationJob
  queue_as :default

  def perform(user_id: nil, max_recordings: 5)
    # If no user_id specified, process all users (for recurring cleanup)
    if user_id.nil?
      Rails.logger.info "🎥 Starting bulk PostHog recordings cleanup for all users"
      User.find_each(batch_size: 50) do |user|
        process_user_recordings(user.id, max_recordings)
      end
      Rails.logger.info "🎥 Completed bulk PostHog recordings cleanup"
      return
    end

    # Process specific user
    process_user_recordings(user_id, max_recordings)
  end

  private

  def process_user_recordings(user_id, max_recordings)
    return unless user_id.present?

    user = User.find_by(id: user_id)
    return unless user

    Rails.logger.info "🎥 Managing PostHog recordings for user #{user_id} (#{user.email})"

    begin
      # Track the management event
      PosthogService.track_recording_event(
        user_id: user_id,
        event_type: 'management_started',
        recording_data: {
          max_recordings: max_recordings,
          trigger: 'automatic_cleanup'
        }
      )

      # Get current recordings and manage them
      recordings = PosthogService.get_user_recordings(user_id: user_id, limit: 20)
      initial_count = recordings.length

      if recordings.length > max_recordings
        # Manage recordings (delete old ones)
        cleanup_performed = PosthogService.manage_user_recordings(
          user_id: user_id, 
          max_recordings: max_recordings
        )

        if cleanup_performed
          final_recordings = PosthogService.get_user_recordings(user_id: user_id, limit: 10)
          final_count = final_recordings.length
          deleted_count = initial_count - final_count

          # Track successful cleanup
          PosthogService.track_recording_event(
            user_id: user_id,
            event_type: 'cleanup_completed',
            recording_data: {
              initial_count: initial_count,
              final_count: final_count,
              deleted_count: deleted_count,
              max_recordings: max_recordings
            }
          )

          Rails.logger.info "🎥 PostHog recordings cleanup completed for user #{user_id}: #{deleted_count} recordings deleted"
        else
          Rails.logger.warn "🎥 PostHog recordings cleanup failed for user #{user_id}"
        end
      else
        # No cleanup needed
        PosthogService.track_recording_event(
          user_id: user_id,
          event_type: 'no_cleanup_needed',
          recording_data: {
            current_count: initial_count,
            max_recordings: max_recordings
          }
        )

        Rails.logger.info "🎥 No PostHog recordings cleanup needed for user #{user_id} (#{initial_count} recordings)"
      end

    rescue => e
      Rails.logger.error "🎥 PostHog recordings management failed for user #{user_id}: #{e.message}"
      
      # Track the error
      PosthogService.track_recording_event(
        user_id: user_id,
        event_type: 'management_failed',
        recording_data: {
          error_message: e.message,
          error_class: e.class.name
        }
      )
    end
  end

  # Class method to schedule cleanup for a user
  def self.schedule_for_user(user_id:, delay: 30.seconds)
    perform_later(user_id: user_id)
  end

  # Class method to schedule cleanup for all users (for maintenance)
  def self.cleanup_all_users
    User.find_each do |user|
      perform_later(user_id: user.id)
    end
  end
end 