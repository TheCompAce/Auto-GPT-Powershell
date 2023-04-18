3. RunSystemPlugins.ps1: Searches for and runs system plugins in the "plugins" folder. Example:
   - plugins/System_Sample.ps1: A sample system plugin that leaves the system message unchanged

4. RunOutputPlugins.ps1: Searches for and runs output plugins in the "plugins" folder. Example:
   - plugins/Output_CodeSaver.ps16: Strips code out into "source_[time].txt" unless "Allow GPT in plugins" is enabled, then it will try to use ChatGPT to get the filename. (This will save multiple files, as some seem to get overy written with bad data.)
   - plugins/Output_SessionLog.ps1: A sample output plugin that logs the output to a session file

## Creating Plugins 🛠️

AutoGPT_PS includes a plugin system that allows for easy customization of input processing, output formatting, and more. There are four types of plugins:

1. Start plugins
2. Input plugins
3. Output plugins
4. System plugins

For the base setup of each plugin type, see the scripts provided in the "plugins" folder.

## To Do 📝

- Improve error handling and user feedback.
- Add more plugin examples to showcase the versatility of the plugin system.
- Enhance the plugin system by allowing for more customization options.
- Create a user-friendly interface for managing plugin configuration.
- Streamline the process of adding new plugins and managing existing ones.
- Keep the project up-to-date with the latest GPT-4 model improvements and enhancements.
