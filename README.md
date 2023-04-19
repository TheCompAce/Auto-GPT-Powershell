# AutoGPT_PS 😄

AutoGPT_PS is a PowerShell script that runs GPT-4, processes user input, and returns generated responses. The script includes a plugin system that allows for easy customization of input processing, output formatting, and more.

## Usage 🚀

1. Download the AutoGPT_PS repository.
2. Place the GPT-4 model file in the same directory as the AutoGPT.ps1 script.
3. Run the AutoGPT.ps1 script.
4. Select `y` to go to the Options.
5. Enter the Starting Prompt (If using OpenAI GPT 3.5 or higher, then you will also be asked for a System Prompt.)
6. The Main Loop will run; if you have set the Loop Count to Infinite, press Ctrl-C to cancel.
7. Once completed, there will be a time-stamped "session_[time]" folder in the "sessions" folder, containing "session_[time].txt" file with the prompts and responses passed back and forth. If "Output Session Log Plugin" is enabled.

### How to get the GPT4ALL model! 💾
Download the `gpt4all-lora-quantized.bin` file from [Direct Link](https://the-eye.eu/public/AI/models/nomic-ai/gpt4all/gpt4all-lora-quantized.bin) or [[Torrent-Magnet]](https://tinyurl.com/gpt4all-lora-quantized).

## Workflow 🔄

1. Start the script.
2. Ask if you want to change the options (if yes, then change options then return here, if no continue on).
3. Ask for your "Start Prompt" - what to first ask the GPT, then "Start System" (if using OpenAI ChatGPT).
4. Call the plugins for the "Start" (this is only called once) to change the prompt.
5. Create the "Main" loop.
6. In the "Main Loop", run the "System" plugins against the "Start System", then run the plugins for "Input" on the prompt.
7. Send the prompt and the System to the GPT.
8. When a response is received, run the "Output" plugins on the response.
9. Once the response has been processed, save the response to the prompt and loop back to "Main".

## Options ⚙️

1. **Change Model**: Allows selection of a .bin file to use for GPT4All. Example: `gpt4all-lora-quantized.bin`.
2. **Toggle Pause**: Enables or disables pausing after every iteration of the main loop. Default value: `y` (pause).
3. **Change Seed**: Sets the seed value for GPT4All. Default value: `` (use the first generated seed) ('0' will use a random seed every time).
4. **Change Loop Count**: Sets the number of loops for the main loop. Default value: `10` (ten loops).
5. **Toggle Use ChatGPT**: Enables or disables the use of the OpenAI Chat API. Default value: `False` (disabled).
6. **Set OpenAI Key**: Sets the OpenAI API key.
7. **OpenAI Models**: Allows selection of an OpenAI model from the available options: `text-davinci-003`, `gpt-3.5-turbo`, and `gpt-4`. Default value: `text-davinci-003`.
8. **Allow GPT in plugins**: Allows plugins to use the settings for OpenAI. Default value: `False`
9. **Turn On Debug**: Enables or disables debug messages at most steps of the scripts. Default value: `False` (disabled).
10. **Plugin Settings**: Allows you to Enable and change settings of Plugins.

To update these options, select "y" when it prompts "Do you want to check options? (y)es/(n)o:" at the start.

## Default Plugins 🔌

The plugin system is based on separate modules for different types of plugins:

1. RunStartPlugins.ps1: Searches for and runs start plugins in the "plugins" folder. Example:
   - plugins/Start_Sample.ps1: A sample start plugin that leaves the start message unchanged

2. RunInputPlugins.ps1: Searches for and runs input plugins in the "plugins" folder. Example:
   - plugins/Input_Sample.ps1: A sample input plugin that leaves the prompt unchanged

3. RunSystemPlugins.ps1: Searches for and runs system plugins in the "plugins" folder. Example:
   - plugins/System_Sample.ps1: A sample system plugin that leaves the system message unchanged

4. RunOutputPlugins.ps1: Searches for and runs output plugins in the "plugins" folder. Example:
   - plugins/Output_CodeSaver.ps1: Strips code out into "source_[time].txt" unless "Allow GPT in plugins" is enabled, then it will try to use ChatGPT to get the filename. (This will save multiple files, as some seem to get overy written with bad data.)
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

## Contribute 🤝

We welcome contributions to the AutoGPT_PS project! There are many ways to get involved:

## Credits 🏆
- "gpt4all-lora-quantized-win64.exe" is used from https://github.com/nomic-ai/gpt4all
- ChatGPT 4.0 it has written about 60% of this code.