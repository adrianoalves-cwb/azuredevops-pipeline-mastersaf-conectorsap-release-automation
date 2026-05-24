# SeleniumExtension.py
from robot.api.deco import keyword
from selenium.webdriver import FirefoxProfile


class SeleniumExtension:

    @keyword("Set Up Firefox Profile")
    def setup_firefox(self):
        profile = FirefoxProfile()
        profile.set_preference("browser.download.folderList", 2)

        # Uncomment to set custom download dir
        profile.set_preference("browser.download.dir", "#{TEMP_FOLDER}#")

        # To make sure that browser won't try open pdf in browser
        profile.set_preference("pdfjs.disabled", True)

        profile.set_preference(
            "browser.helperApps.neverAsk.saveToDisk",
            "image/jpeg"\
            "application/octet-stream"
        )

        profile.update_preferences()
        return profile.path