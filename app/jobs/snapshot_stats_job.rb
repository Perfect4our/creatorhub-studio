class SnapshotStatsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting SnapshotStatsJob at #{Time.current}"
    
    # Process each active subscription
    Subscription.active.find_each do |subscription|
      Rails.logger.info "Processing subscription ##{subscription.id} (#{subscription.platform})"
      
      # Skip if no service class is available
      unless subscription.service_class
        Rails.logger.warn "No service class found for platform: #{subscription.platform}"
        next
      end
      
      # Sync stats for this subscription
      begin
        result = subscription.sync_stats!
        if result
          Rails.logger.info "Successfully synced stats for subscription ##{subscription.id}"
        else
          Rails.logger.warn "Failed to sync stats for subscription ##{subscription.id}"
        end
      rescue => e
        Rails.logger.error "Error syncing stats for subscription ##{subscription.id}: #{e.message}"
      end
    end
    
    Rails.logger.info "Completed SnapshotStatsJob at #{Time.current}"
  end
end
