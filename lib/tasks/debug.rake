namespace :tiktok_studio do
  desc "Debug TikTok Studio application health and configuration"
  task debug: :environment do
    puts "\n🔍 TikTok Studio Debug Report"
    puts "=" * 50
    
    debug_results = []
    
    # 1. Environment Setup
    puts "\n📋 Environment Setup"
    puts "-" * 20
    
    env_result = check_environment
    debug_results << env_result
    print_check_result("Rails Environment", env_result[:status], env_result[:details])
    
    env_vars_result = check_required_env_vars
    debug_results << env_vars_result
    print_check_result("Environment Variables", env_vars_result[:status], env_vars_result[:details])
    
    # 2. Database Checks
    puts "\n💾 Database Health"
    puts "-" * 20
    
    db_result = check_database_health
    debug_results << db_result
    print_check_result("Database Connection", db_result[:status], db_result[:details])
    
    subscriptions_result = check_subscriptions
    debug_results << subscriptions_result
    print_check_result("Subscriptions Data", subscriptions_result[:status], subscriptions_result[:details])
    
    daily_stats_result = check_daily_stats
    debug_results << daily_stats_result
    print_check_result("Daily Stats", daily_stats_result[:status], daily_stats_result[:details])
    
    # 3. Background Jobs
    puts "\n⚙️  Background Jobs"
    puts "-" * 20
    
    sidekiq_result = check_sidekiq_status
    debug_results << sidekiq_result
    print_check_result("Sidekiq Status", sidekiq_result[:status], sidekiq_result[:details])
    
    jobs_result = check_failed_jobs
    debug_results << jobs_result
    print_check_result("Failed Jobs", jobs_result[:status], jobs_result[:details])
    
    # 4. API Connections
    puts "\n🌐 API Connections"
    puts "-" * 20
    
    api_results = check_api_connections
    api_results.each do |result|
      debug_results << result
      print_check_result("#{result[:platform]} API", result[:status], result[:details])
    end
    
    # 5. View Health
    puts "\n👁️  View Health"
    puts "-" * 20
    
    views_result = check_view_health
    debug_results << views_result
    print_check_result("View Variables", views_result[:status], views_result[:details])
    
    # 6. Routing & Assets
    puts "\n🛣️  Routes & Assets"
    puts "-" * 20
    
    routes_result = check_routes
    debug_results << routes_result
    print_check_result("Critical Routes", routes_result[:status], routes_result[:details])
    
    partials_result = check_partials
    debug_results << partials_result
    print_check_result("Required Partials", partials_result[:status], partials_result[:details])
    
    assets_result = check_assets
    debug_results << assets_result
    print_check_result("Asset Files", assets_result[:status], assets_result[:details])
    
    # 7. JavaScript Health
    puts "\n🟨 JavaScript Health"
    puts "-" * 20
    
    js_syntax_result = check_javascript_syntax
    debug_results << js_syntax_result
    print_check_result("JavaScript Syntax", js_syntax_result[:status], js_syntax_result[:details])
    
    js_errors_result = check_common_js_errors
    debug_results << js_errors_result
    print_check_result("Common JS Issues", js_errors_result[:status], js_errors_result[:details])
    
    # 8. PostHog & Analytics
    puts "\n📊 PostHog & Analytics"
    puts "-" * 20
    
    posthog_result = check_posthog_integration
    debug_results << posthog_result
    print_check_result("PostHog Integration", posthog_result[:status], posthog_result[:details])
    
    analytics_result = check_analytics_tracking
    debug_results << analytics_result
    print_check_result("Analytics Tracking", analytics_result[:status], analytics_result[:details])
    
    # 9. Content Security Policy
    puts "\n🔒 Security Configuration"
    puts "-" * 20
    
    csp_result = check_csp_configuration
    debug_results << csp_result
    print_check_result("CSP Configuration", csp_result[:status], csp_result[:details])
    
    cors_result = check_cors_issues
    debug_results << cors_result
    print_check_result("CORS Configuration", cors_result[:status], cors_result[:details])
    
    # 10. Performance & Errors
    puts "\n⚡ Performance & Errors"
    puts "-" * 20
    
    performance_result = check_performance_issues
    debug_results << performance_result
    print_check_result("Performance Issues", performance_result[:status], performance_result[:details])
    
    error_handling_result = check_error_handling
    debug_results << error_handling_result
    print_check_result("Error Handling", error_handling_result[:status], error_handling_result[:details])
    
    # 11. Summary
    print_summary(debug_results)
  end
  
  desc "Grant permanent subscription to a user by email"
  task :grant_permanent_subscription, [:email] => :environment do |task, args|
    email = args[:email]
    
    if email.blank?
      puts "❌ Please provide an email address"
      puts "Usage: rake grant_permanent_subscription[user@example.com]"
      exit 1
    end
    
    user = User.find_by(email: email.downcase)
    
    if user.nil?
      puts "❌ User with email '#{email}' not found"
      exit 1
    end
    
    if user.permanent_subscription?
      puts "✅ User '#{email}' already has permanent subscription"
    else
      user.update!(permanent_subscription: true)
      puts "✅ Granted permanent subscription to '#{email}'"
    end
    
    puts "\nUser details:"
    puts "  Email: #{user.email}"
    puts "  Name: #{user.name}"
    puts "  Permanent Subscription: #{user.permanent_subscription? ? '✅ Yes' : '❌ No'}"
    puts "  Has Permanent Access: #{user.has_permanent_subscription? ? '✅ Yes' : '❌ No'}"
    puts "  Active Subscriptions: #{user.subscriptions.where(active: true).count}"
  end
  
  desc "List users with permanent subscription access"
  task :list_permanent_users => :environment do
    puts "🔍 Users with permanent subscription access:\n\n"
    
    # Users with permanent_subscription flag
    permanent_flag_users = User.where(permanent_subscription: true)
    
    # Users in the permanent emails list
    permanent_email_users = User.where('LOWER(email) IN (?)', User::PERMANENT_SUBSCRIPTION_EMAILS.map(&:downcase))
    
    # Combine and deduplicate
    all_permanent_users = (permanent_flag_users.to_a + permanent_email_users.to_a).uniq
    
    if all_permanent_users.empty?
      puts "❌ No users found with permanent subscription access"
    else
      all_permanent_users.each do |user|
        puts "✅ #{user.email} (#{user.name})"
        puts "   Permanent flag: #{user.permanent_subscription? ? '✅' : '❌'}"
        puts "   In emails list: #{User::PERMANENT_SUBSCRIPTION_EMAILS.map(&:downcase).include?(user.email.downcase) ? '✅' : '❌'}"
        puts "   Active subscriptions: #{user.subscriptions.where(active: true).count}"
        puts ""
      end
    end
  end
  
  private
  
  def check_javascript_syntax
    begin
      js_erb_files = [
        'app/views/pages/dashboard.html.erb',
        'app/views/shared/_realtime_stats.html.erb'
      ]
      
      issues = []
      
      js_erb_files.each do |file|
        next unless File.exist?(file)
        
        content = File.read(file)
        lines = content.split("\n")
        
        # Check for common JavaScript syntax issues
        lines.each_with_index do |line, index|
          line_num = index + 1
          
          # Look for JavaScript variable declarations in ERB files
          if line.match?(/\s*(let|const|var)\s+\w+/)
            # Check for redeclaration patterns
            var_name = line.match(/\s*(let|const|var)\s+(\w+)/)[2]
            
            # Count occurrences of this variable declaration
            occurrences = lines.count { |l| l.match?(/\s*(let|const|var)\s+#{Regexp.escape(var_name)}/) }
            
            if occurrences > 1
              issues << "#{file}:#{line_num} - Variable '#{var_name}' declared multiple times (use window.#{var_name} for global scope)"
            end
          end
          
          # Check for common syntax errors
          if line.include?("replaceWith'") && line.include?("'Element'")
            issues << "#{file}:#{line_num} - Possible replaceWith syntax error"
          end
          
          # Check for unclosed script tags
          if line.include?("<script") && !line.include?(">")
            next_lines = lines[(index + 1)..(index + 5)]
            unless next_lines&.any? { |l| l.include?(">") }
              issues << "#{file}:#{line_num} - Unclosed script tag"
            end
          end
          
          # Check for Turbo-specific issues
          if line.include?("dashboardInitialized") && !line.include?("window.")
            issues << "#{file}:#{line_num} - Using dashboardInitialized without window scope (may cause redeclaration)"
          end
          
          if line.include?("dropdownInitialized") && !line.include?("window.")
            issues << "#{file}:#{line_num} - Using dropdownInitialized without window scope (may cause redeclaration)"
          end
        end
      end
      
      if issues.empty?
        { status: :pass, details: "No JavaScript syntax issues detected", platform: "JavaScript" }
      else
        { status: :warn, details: "#{issues.length} issues found: #{issues.first(3).join('; ')}", platform: "JavaScript" }
      end
    rescue => e
      { status: :fail, details: "Error checking JavaScript syntax: #{e.message}", platform: "JavaScript" }
    end
  end
  
  def check_common_js_errors
    begin
      erb_files = Dir.glob(['app/views/**/*.html.erb', 'app/views/**/*.js.erb'])
      issues = []
      
      erb_files.each do |file|
        content = File.read(file)
        
        # Check for Bootstrap dropdown issues
        if content.include?('bootstrap.Dropdown') && !content.include?('dispose()')
          issues << "#{file} - Bootstrap dropdown without proper cleanup (may get stuck)"
        end
        
        # Check for missing error handling
        if content.include?('new Chart(') && !content.include?('try') && !content.include?('catch')
          issues << "#{file} - Chart.js initialization without error handling"
        end
        
        # Check for Turbo-related issues
        if content.include?("addEventListener('turbo:") && !content.include?("addEventListener('turbo:before-")
          issues << "#{file} - Turbo event listeners without cleanup handling"
        end
        
        # Check for potential memory leaks
        if content.match?(/setInterval\s*\(/) && !content.include?('clearInterval')
          issues << "#{file} - setInterval without clearInterval (potential memory leak)"
        end
        
        # Check for jQuery conflicts with Turbo
        if content.include?('$(document).ready') && content.include?('turbo:')
          issues << "#{file} - Mixing jQuery document.ready with Turbo events (may cause conflicts)"
        end
      end
      
      if issues.empty?
        { status: :pass, details: "No common JavaScript issues detected", platform: "JavaScript" }
      else
        { status: :warn, details: "#{issues.length} potential issues: #{issues.first(2).join('; ')}", platform: "JavaScript" }
      end
    rescue => e
      { status: :fail, details: "Error checking common JS issues: #{e.message}", platform: "JavaScript" }
    end
  end

  def check_environment
    begin
      env = Rails.env
      details = "Current environment: #{env}"
      if %w[development test production].include?(env)
        { status: :pass, details: details, platform: "Environment" }
      else
        { status: :warn, details: "#{details} (non-standard environment)", platform: "Environment" }
      end
    rescue => e
      { status: :fail, details: "Error checking environment: #{e.message}", platform: "Environment" }
    end
  end
  
  def check_required_env_vars
    required_vars = [
      'TIKTOK_CLIENT_KEY',
      'TIKTOK_CLIENT_SECRET', 
      'YOUTUBE_API_KEY',
      'INSTAGRAM_APP_ID',
      'INSTAGRAM_APP_SECRET',
      'TWITTER_API_KEY',
      'TWITTER_API_SECRET',
      'FACEBOOK_APP_ID',
      'FACEBOOK_APP_SECRET',
      'LINKEDIN_CLIENT_ID',
      'LINKEDIN_CLIENT_SECRET',
      'TWITCH_CLIENT_ID',
      'TWITCH_CLIENT_SECRET'
    ]
    
    missing_vars = []
    present_vars = []
    
    required_vars.each do |var|
      if ENV[var].present?
        present_vars << var
      else
        missing_vars << var
      end
    end
    
    if missing_vars.empty?
      { status: :pass, details: "All #{present_vars.count} environment variables present", platform: "Environment" }
    elsif missing_vars.count < required_vars.count / 2
      { status: :warn, details: "Missing: #{missing_vars.join(', ')}", platform: "Environment" }
    else
      { status: :fail, details: "Missing critical variables: #{missing_vars.join(', ')}", platform: "Environment" }
    end
  rescue => e
    { status: :fail, details: "Error checking environment variables: #{e.message}", platform: "Environment" }
  end
  
  def check_database_health
    begin
      ActiveRecord::Base.connection.execute("SELECT 1")
      { status: :pass, details: "Database connection successful", platform: "Database" }
    rescue => e
      { status: :fail, details: "Database connection failed: #{e.message}", platform: "Database" }
    end
  end
  
  def check_subscriptions
    begin
      total_subs = Subscription.count
      active_subs = Subscription.where(active: true).count
      
      # Check for required fields
      missing_platform = Subscription.where(platform: [nil, '']).count
      missing_user = Subscription.where(user_id: nil).count
      missing_auth = Subscription.where(auth_token: [nil, '']).count
      
      issues = []
      issues << "#{missing_platform} missing platform" if missing_platform > 0
      issues << "#{missing_user} orphaned (no user)" if missing_user > 0  
      issues << "#{missing_auth} missing auth_token" if missing_auth > 0
      
      if issues.empty?
        { status: :pass, details: "#{total_subs} total, #{active_subs} active subscriptions", platform: "Database" }
      else
        { status: :warn, details: "Issues found: #{issues.join(', ')}", platform: "Database" }
      end
    rescue => e
      { status: :fail, details: "Error checking subscriptions: #{e.message}", platform: "Database" }
    end
  end
  
  def check_daily_stats
    begin
      today_stats = DailyStat.where(date: Date.current).count
      total_stats = DailyStat.count
      
      if today_stats > 0
        { status: :pass, details: "#{today_stats} stats for today, #{total_stats} total", platform: "Database" }
      elsif total_stats > 0
        { status: :warn, details: "No stats for today, but #{total_stats} historical records", platform: "Database" }
      else
        { status: :warn, details: "No daily stats found - may need initial data fetch", platform: "Database" }
      end
    rescue => e
      { status: :fail, details: "Error checking daily stats: #{e.message}", platform: "Database" }
    end
  end
  
  def check_sidekiq_status
    begin
      if defined?(Sidekiq) && Object.const_defined?('Sidekiq::Stats')
        # Try to get Sidekiq stats
        stats = Sidekiq::Stats.new
        { status: :pass, details: "Sidekiq running - #{stats.processed} processed, #{stats.failed} failed", platform: "Jobs" }
      elsif defined?(Sidekiq)
        { status: :warn, details: "Sidekiq loaded but Stats not available - may be in test mode", platform: "Jobs" }
      else
        { status: :warn, details: "Sidekiq not loaded - background jobs may not be available", platform: "Jobs" }
      end
    rescue Redis::CannotConnectError
      { status: :fail, details: "Cannot connect to Redis - Sidekiq unavailable", platform: "Jobs" }
    rescue NameError => e
      { status: :warn, details: "Sidekiq constants not available: #{e.message}", platform: "Jobs" }
    rescue => e
      { status: :warn, details: "Cannot check Sidekiq status: #{e.message}", platform: "Jobs" }
    end
  end
  
  def check_failed_jobs
    begin
      if defined?(Sidekiq) && Object.const_defined?('Sidekiq::RetrySet') && Object.const_defined?('Sidekiq::DeadSet')
        retry_set = Sidekiq::RetrySet.new
        dead_set = Sidekiq::DeadSet.new
        
        if retry_set.size == 0 && dead_set.size == 0
          { status: :pass, details: "No failed jobs", platform: "Jobs" }
        else
          { status: :warn, details: "#{retry_set.size} retrying, #{dead_set.size} dead jobs", platform: "Jobs" }
        end
      elsif defined?(Sidekiq)
        { status: :skip, details: "Sidekiq loaded but job queue classes not available", platform: "Jobs" }
      else
        { status: :skip, details: "Sidekiq not available", platform: "Jobs" }
      end
    rescue NameError => e
      { status: :skip, details: "Sidekiq job classes not available: #{e.message}", platform: "Jobs" }
    rescue => e
      { status: :warn, details: "Cannot check failed jobs: #{e.message}", platform: "Jobs" }
    end
  end
  
  def check_api_connections
    results = []
    
    # Define service classes and their test methods
    services = {
      'TikTok' => 'TiktokService',
      'YouTube' => 'YoutubeService', 
      'Instagram' => 'InstagramService',
      'Twitter' => 'TwitterService',
      'Facebook' => 'FacebookService',
      'LinkedIn' => 'LinkedinService',
      'Twitch' => 'TwitchService'
    }
    
    services.each do |platform, service_class|
      begin
        if Object.const_defined?(service_class)
          service = service_class.constantize
          
          # Special handling for YouTube to check Analytics API
          if platform == 'YouTube'
            results.concat(check_youtube_api_detailed)
          elsif service.respond_to?(:test_connection)
            test_result = service.test_connection
            results << { status: :pass, details: "API connection successful", platform: platform }
          else
            # Check if we can at least instantiate the service
            service.new rescue nil
            results << { status: :skip, details: "Service available but no test method", platform: platform }
          end
        else
          results << { status: :skip, details: "Service class not found", platform: platform }
        end
      rescue => e
        results << { status: :fail, details: "API test failed: #{e.message}", platform: platform }
      end
    end
    
    results
  end
  
  def check_youtube_api_detailed
    results = []
    
    # Check YouTube Data API v3
    begin
      api_key = Rails.application.credentials.youtube&.api_key || ENV['YOUTUBE_API_KEY']
      client_id = Rails.application.credentials.youtube&.client_id || ENV['YOUTUBE_CLIENT_ID']
      client_secret = Rails.application.credentials.youtube&.client_secret || ENV['YOUTUBE_CLIENT_SECRET']
      
      if api_key.present? && client_id.present? && client_secret.present?
        # Test Data API v3 connection
        uri = URI('https://www.googleapis.com/youtube/v3/channels')
        params = { part: 'snippet', forUsername: 'YouTube', key: api_key }
        uri.query = URI.encode_www_form(params)
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        response = http.get(uri)
        
        if response.code == '200'
          results << { status: :pass, details: "YouTube Data API v3 working", platform: "YouTube Data" }
        else
          results << { status: :fail, details: "YouTube Data API v3 failed (#{response.code})", platform: "YouTube Data" }
        end
      else
        missing = []
        missing << "API Key" unless api_key.present?
        missing << "Client ID" unless client_id.present?
        missing << "Client Secret" unless client_secret.present?
        results << { status: :fail, details: "Missing credentials: #{missing.join(', ')}", platform: "YouTube Data" }
      end
    rescue => e
      results << { status: :fail, details: "YouTube Data API error: #{e.message}", platform: "YouTube Data" }
    end
    
    # Check YouTube Analytics API status
    begin
      youtube_subs = Subscription.where(platform: 'youtube', active: true)
      
      if youtube_subs.any?
        analytics_enabled = 0
        analytics_available = 0
        
        youtube_subs.each do |sub|
          youtube_service = YoutubeService.new(sub)
          begin
            if youtube_service.respond_to?(:analytics_api_available?) && youtube_service.analytics_api_available?
              analytics_enabled += 1
              
              # Test Analytics API call
              begin
                analytics_data = youtube_service.get_analytics_data(7.days.ago, Date.current)
                analytics_available += 1
              rescue => e
                # Analytics API call failed
              end
            end
          rescue => e
            Rails.logger.warn "Error checking analytics for subscription #{sub.id}: #{e.message}"
          end
        end
        
        if analytics_enabled > 0
          if analytics_available == analytics_enabled
            results << { status: :pass, details: "Analytics API: #{analytics_enabled}/#{youtube_subs.count} accounts enabled and working", platform: "YouTube Analytics" }
          else
            results << { status: :warn, details: "Analytics API: #{analytics_enabled}/#{youtube_subs.count} enabled, #{analytics_available} working", platform: "YouTube Analytics" }
          end
        else
          results << { status: :warn, details: "Analytics API: Not enabled for any accounts (#{youtube_subs.count} basic connections)", platform: "YouTube Analytics" }
        end
      else
        results << { status: :skip, details: "No YouTube accounts connected", platform: "YouTube Analytics" }
      end
    rescue => e
      results << { status: :fail, details: "Analytics API check error: #{e.message}", platform: "YouTube Analytics" }
    end
    
    results
  end
  
  def check_view_health
    begin
      critical_variables = ['@stats', '@chart_data', '@platform_stats', '@subscriptions']
      view_files = [
        'app/views/pages/dashboard.html.erb',
        'app/views/shared/_realtime_stats.html.erb'
      ]
      
      issues = []
      
      view_files.each do |file|
        if File.exist?(file)
          content = File.read(file)
          critical_variables.each do |var|
            if content.include?(var) && !content.include?("#{var} ||=") && !content.include?("#{var}&.")
              issues << "#{file} uses #{var} without nil safety"
            end
          end
        else
          issues << "Missing view file: #{file}"
        end
      end
      
      if issues.empty?
        { status: :pass, details: "View files look healthy", platform: "Views" }
      else
        { status: :warn, details: issues.join('; '), platform: "Views" }
      end
    rescue => e
      { status: :fail, details: "Error checking views: #{e.message}", platform: "Views" }
    end
  end
  
  def check_routes
    begin
      routes = Rails.application.routes.routes
      route_names = routes.map(&:name).compact
      
      required_routes = ['dashboard', 'subscriptions']
      missing_routes = required_routes - route_names
      
      if missing_routes.empty?
        { status: :pass, details: "All critical routes present", platform: "Routes" }
      else
        { status: :fail, details: "Missing routes: #{missing_routes.join(', ')}", platform: "Routes" }
      end
    rescue => e
      { status: :fail, details: "Error checking routes: #{e.message}", platform: "Routes" }
    end
  end
  
  def check_partials
    begin
      required_partials = [
        'app/views/shared/_main_data.html.erb',
        'app/views/shared/_realtime_stats.html.erb', 
        'app/views/shared/_navbar.html.erb',
        'app/views/shared/_footer.html.erb'
      ]
      
      missing_partials = required_partials.reject { |file| File.exist?(file) }
      
      if missing_partials.empty?
        { status: :pass, details: "All required partials present", platform: "Assets" }
      else
        { status: :warn, details: "Missing partials: #{missing_partials.join(', ')}", platform: "Assets" }
      end
    rescue => e
      { status: :fail, details: "Error checking partials: #{e.message}", platform: "Assets" }
    end
  end
  
  def check_assets
    begin
      css_files = [
        'app/assets/stylesheets/application.css',
        'app/assets/stylesheets/custom.css',
        'app/assets/stylesheets/multi_platform.css'
      ]
      
      js_files = [
        'app/javascript/application.js',
        'app/javascript/controllers/application.js',
        'app/javascript/controllers/index.js',
        'app/javascript/controllers/hello_controller.js',
        'app/javascript/controllers/notification_controller.js',
        'app/javascript/controllers/theme_controller.js',
        'app/javascript/controllers/platform_controller.js',
        'app/javascript/controllers/video_controller.js',
        'app/javascript/controllers/demographics_controller.js'
      ]
      
      missing_css = css_files.reject { |file| File.exist?(file) }
      missing_js = js_files.reject { |file| File.exist?(file) }
      
      details = []
      if missing_css.empty?
        details << "All CSS files present"
      else
        details << "Missing CSS: #{missing_css.join(', ')}"
      end
      
      if missing_js.empty?
        details << "All JS controllers present"
      else
        details << "Missing JS: #{missing_js.join(', ')}"
      end
      
      if missing_css.empty? && missing_js.empty?
        { status: :pass, details: details.join('; '), platform: "Assets" }
      else
        { status: :warn, details: details.join('; '), platform: "Assets" }
      end
    rescue => e
      { status: :fail, details: "Error checking assets: #{e.message}", platform: "Assets" }
    end
  end
  
  def print_check_result(name, status, details)
    status_icon = case status
                  when :pass then "✅"
                  when :warn then "⚠️ "
                  when :fail then "❌"
                  when :skip then "⏭️ "
                  else "❓"
                  end
    
    puts "#{status_icon} #{name}: #{details}"
  end
  
  def print_summary(results)
    puts "\n📊 Summary"
    puts "=" * 50
    
    passed = results.count { |r| r[:status] == :pass }
    warnings = results.count { |r| r[:status] == :warn }
    failed = results.count { |r| r[:status] == :fail }
    skipped = results.count { |r| r[:status] == :skip }
    
    puts "✅ Passed: #{passed}"
    puts "⚠️  Warnings: #{warnings}" if warnings > 0
    puts "❌ Failed: #{failed}" if failed > 0
    puts "⏭️  Skipped: #{skipped}" if skipped > 0
    
    puts "\n" + "=" * 50
    
    if failed > 0
      puts "🚨 CRITICAL ISSUES FOUND - Application may not function properly"
      puts "\nFailed checks:"
      results.select { |r| r[:status] == :fail }.each do |result|
        puts "  ❌ #{result[:platform]}: #{result[:details]}"
      end
    elsif warnings > 0
      puts "⚠️  Some issues detected - Application should work but may have reduced functionality"
    else
      puts "🎉 All checks passed - Application appears healthy!"
    end
    
    puts "\nRun 'rails tiktok_studio:debug' again after fixing issues."
    puts ""
  end

  def check_posthog_integration
    begin
      # Check PostHog configuration
      issues = []
      
      # Check if PostHog is properly configured
      layout_content = File.read('app/views/layouts/application.html.erb')
      
      if layout_content.include?('window.posthog')
        if layout_content.include?('/analytics/track')
          { status: :pass, details: "PostHog configured with local analytics endpoint (CORS-safe)", platform: "PostHog" }
        else
          issues << "PostHog may have CORS issues - consider using local analytics endpoint"
          { status: :warn, details: issues.join('; '), platform: "PostHog" }
        end
      else
        { status: :warn, details: "PostHog not found in layout - analytics may not be working", platform: "PostHog" }
      end
    rescue => e
      { status: :fail, details: "Error checking PostHog: #{e.message}", platform: "PostHog" }
    end
  end

  def check_analytics_tracking
    begin
      # Check analytics controller and routes
      issues = []
      
      # Check if analytics controller has track_event action
      controller_content = File.read('app/controllers/analytics_controller.rb')
      unless controller_content.include?('def track_event')
        issues << "Missing track_event action in AnalyticsController"
      end
      
      # Check routes
      routes_content = File.read('config/routes.rb')
      unless routes_content.include?('post "/analytics/track"') || routes_content.include?("post '/analytics/track'")
        issues << "Missing analytics tracking route"
      end
      
      # Check analytics JavaScript controller
      if File.exist?('app/javascript/controllers/analytics_controller.js')
        js_content = File.read('app/javascript/controllers/analytics_controller.js')
        unless js_content.include?('trackEvent')
          issues << "Analytics controller missing trackEvent method"
        end
      else
        issues << "Missing analytics JavaScript controller"
      end
      
      if issues.empty?
        { status: :pass, details: "Analytics tracking properly configured", platform: "Analytics" }
      else
        { status: :warn, details: issues.join('; '), platform: "Analytics" }
      end
    rescue => e
      { status: :fail, details: "Error checking analytics: #{e.message}", platform: "Analytics" }
    end
  end

  def check_csp_configuration
    begin
      csp_content = File.read('config/initializers/content_security_policy.rb')
      
      if csp_content.include?('Rails.env.development?')
        { status: :pass, details: "CSP properly configured for development/production", platform: "CSP" }
      elsif csp_content.include?('policy.script_src')
        { status: :warn, details: "CSP configured but may be too restrictive", platform: "CSP" }
      else
        { status: :skip, details: "CSP not configured", platform: "CSP" }
      end
    rescue => e
      { status: :fail, details: "Error checking CSP: #{e.message}", platform: "CSP" }
    end
  end

  def check_cors_issues
    begin
      issues = []
      
      # Check for external PostHog domains in application layout
      layout_content = File.read('app/views/layouts/application.html.erb')
      
      external_domains = ['i.posthog.com', 'us-assets.i.posthog.com', 'app.posthog.com']
      cors_risks = external_domains.select { |domain| layout_content.include?(domain) }
      
      if cors_risks.any?
        issues << "External domains detected: #{cors_risks.join(', ')} (potential CORS issues)"
      end
      
      # Check if using local analytics endpoint
      if layout_content.include?('/analytics/track')
        issues << "Using local analytics endpoint (good for avoiding CORS)"
      end
      
      if issues.empty?
        { status: :pass, details: "No obvious CORS issues detected", platform: "CORS" }
      elsif issues.any? { |i| i.include?('potential CORS') }
        { status: :warn, details: issues.join('; '), platform: "CORS" }
      else
        { status: :pass, details: issues.join('; '), platform: "CORS" }
      end
    rescue => e
      { status: :fail, details: "Error checking CORS: #{e.message}", platform: "CORS" }
    end
  end

  def check_performance_issues
    begin
      issues = []
      
      # Check for potential infinite loops in JavaScript
      js_files = [
        'app/javascript/controllers/analytics_controller.js',
        'app/javascript/controllers/request_manager_controller.js'
      ]
      
      js_files.each do |file|
        if File.exist?(file)
          content = File.read(file)
          
          # Check for recursion guards
          unless content.include?('recursionGuard') || content.include?('recursion_guard')
            issues << "#{file} may lack recursion protection"
          end
          
          # Check for rate limiting
          unless content.include?('setTimeout') || content.include?('throttle') || content.include?('debounce')
            issues << "#{file} may lack rate limiting"
          end
        end
      end
      
      if issues.empty?
        { status: :pass, details: "No obvious performance issues detected", platform: "Performance" }
      else
        { status: :warn, details: issues.join('; '), platform: "Performance" }
      end
    rescue => e
      { status: :fail, details: "Error checking performance: #{e.message}", platform: "Performance" }
    end
  end

  def check_error_handling
    begin
      issues = []
      
      # Check dashboard for JavaScript error handling
      dashboard_content = File.read('app/views/pages/dashboard.html.erb')
      
      # Look for try-catch blocks
      try_catch_count = dashboard_content.scan(/try\s*{/).length
      error_handling_count = dashboard_content.scan(/catch\s*\(/).length
      
      if try_catch_count > 0 && error_handling_count > 0
        { status: :pass, details: "Error handling present in dashboard", platform: "Error Handling" }
      elsif dashboard_content.include?('console.error') || dashboard_content.include?('console.warn')
        { status: :warn, details: "Some error logging present but limited try-catch", platform: "Error Handling" }
      else
        { status: :warn, details: "Limited error handling in dashboard", platform: "Error Handling" }
      end
    rescue => e
      { status: :fail, details: "Error checking error handling: #{e.message}", platform: "Error Handling" }
    end
  end
end 