import { application } from "./application"

import FlashController from "./flash_controller"
import MobileMenuController from "./mobile_menu_controller"
import DropdownController from "./dropdown_controller"
import SearchController from "./search_controller"
import FadeInController from "./fade_in_controller"
import ImagePreviewController from "./image_preview_controller"

application.register("flash", FlashController)
application.register("mobile-menu", MobileMenuController)
application.register("dropdown", DropdownController)
application.register("search", SearchController)
application.register("fade-in", FadeInController)
application.register("image-preview", ImagePreviewController)
