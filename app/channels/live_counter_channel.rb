class LiveCounterChannel < ApplicationCable::Channel
  def subscribed
    stream_from "live_counter_channel_#{params[:user_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
  end
end
