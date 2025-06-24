module ApplicationHelper
  def format_large_number(number)
    return '0' if number.nil? || number == 0
    
    case number
    when 0...1_000
      number.to_s
    when 1_000...1_000_000
      "#{(number / 1_000.0).round(1)}K"
    when 1_000_000...1_000_000_000
      "#{(number / 1_000_000.0).round(1)}M"
    else
      "#{(number / 1_000_000_000.0).round(1)}B"
    end
  end
  
  def format_watch_time(hours)
    return '0h' if hours.nil? || hours == 0
    
    case hours
    when 0...1_000
      "#{hours.round(0)}h"
    when 1_000...1_000_000
      "#{(hours / 1_000.0).round(1)}K h"
    when 1_000_000...1_000_000_000
      "#{(hours / 1_000_000.0).round(1)}M h"
    else
      "#{(hours / 1_000_000_000.0).round(1)}B h"
    end
  end
  
  def format_revenue(amount)
    return '$0' if amount.nil? || amount == 0
    
    case amount
    when 0...1_000
      "$#{amount.round(2)}"
    when 1_000...1_000_000
      "$#{(amount / 1_000.0).round(1)}K"
    when 1_000_000...1_000_000_000
      "$#{(amount / 1_000_000.0).round(1)}M"
    else
      "$#{(amount / 1_000_000_000.0).round(1)}B"
    end
  end
  
  def has_advanced_analytics?(subscription)
    return false unless subscription
    
    case subscription.platform
    when 'youtube'
      # Check if YouTube Analytics API is enabled
      subscription.auth_token.present? && subscription.refresh_token.present?
    when 'tiktok'
      # TikTok requires business account
      false
    else
      false
    end
  end
  
  def analytics_placeholder_message(platform)
    case platform&.downcase
    when 'youtube'
      'Enable YouTube Analytics API for advanced analytics'
    when 'tiktok'
      'TikTok advanced analytics require business account'
    when 'instagram'
      'Instagram advanced analytics coming soon'
    when 'facebook'
      'Facebook advanced analytics coming soon'
    when 'twitter'
      'Twitter advanced analytics coming soon'
    else
      'Advanced analytics coming soon'
    end
  end
end
