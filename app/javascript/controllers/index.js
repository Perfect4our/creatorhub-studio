// Import and register all your controllers manually for better control
import { application } from "controllers/application"

console.log("🎯 Loading Stimulus controllers manually...")

// Import each controller explicitly
import AdminAnalyticsController from "controllers/admin_analytics_controller"
import AnalyticsController from "controllers/analytics_controller"
import ButtonController from "controllers/button_controller"
import DemographicsController from "controllers/demographics_controller"  
import HelloController from "controllers/hello_controller"
import LoadingController from "controllers/loading_controller"
import NotificationController from "controllers/notification_controller"
import PlatformController from "controllers/platform_controller"
import RequestManagerController from "controllers/request_manager_controller"
import ThemeController from "controllers/theme_controller"
import TimeSelectorController from "controllers/time_selector_controller"
import VideoController from "controllers/video_controller"

console.log("✅ Controllers imported successfully")

// Register each controller with Stimulus
application.register("admin-analytics", AdminAnalyticsController)
application.register("analytics", AnalyticsController)
application.register("button", ButtonController)
application.register("demographics", DemographicsController)
application.register("hello", HelloController)
application.register("loading", LoadingController)
application.register("notification", NotificationController)
application.register("platform", PlatformController)
application.register("request-manager", RequestManagerController)
application.register("theme", ThemeController)
application.register("time-selector", TimeSelectorController)
application.register("video", VideoController)

console.log("🚀 Controllers registered successfully:", Object.keys(application.router.modulesByIdentifier))

// Make notification controller globally available for sidebar
window.notificationController = {
  showNotification: (message, type = 'info') => {
    // Find notification controller instance
    const notificationElement = document.querySelector('[data-controller*="notification"]')
    if (notificationElement) {
      const controller = application.getControllerForElementAndIdentifier(notificationElement, 'notification')
      if (controller) {
        controller.show(message, type)
      }
    } else {
      // Fallback to alert if no notification controller
      alert(message)
    }
  }
}
