class SettingsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @subscriptions = current_user.subscriptions.active.order(:platform)
  end

  def update_realtime
    subscription = current_user.subscriptions.find_by(id: params[:subscription_id])
    
    if subscription
      subscription.update(enable_realtime: params[:enable_realtime])
      
      respond_to do |format|
        format.html { redirect_to settings_path, notice: "Real-time settings updated successfully." }
        format.json { render json: { success: true, subscription_id: subscription.id, enable_realtime: subscription.enable_realtime } }
      end
    else
      respond_to do |format|
        format.html { redirect_to settings_path, alert: "Subscription not found." }
        format.json { render json: { success: false, error: "Subscription not found." }, status: :not_found }
      end
    end
  end
end
