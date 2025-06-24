// Import and register all your controllers
import { application } from "controllers/application"

// Import individual controllers using correct paths
import HelloController from "controllers/hello_controller"
import NotificationController from "controllers/notification_controller"
import ThemeController from "controllers/theme_controller"
import PlatformController from "controllers/platform_controller"
import VideoController from "controllers/video_controller"
import DemographicsController from "controllers/demographics_controller"

// Register controllers with application
application.register("hello", HelloController)
application.register("notification", NotificationController)
application.register("theme", ThemeController)
application.register("platform", PlatformController)
application.register("video", VideoController)
application.register("demographics", DemographicsController)
