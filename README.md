# AutoGPT

AutoGPT is a compact, modular, and user-friendly PowerShell interface for text generation with GPT-4 and OpenAI models. It can run GPT4All for offline text generation and supports plugins to customize input, output, and system behavior.

The script is organized into several files:
- AutoGPT.ps1: The main script
- modules/Options.ps1: Handles user settings and options
- modules/ParseOutput.ps1: Parses the output from GPT-4 executable
- modules/RunChatGPTAPI.ps1: Executes the ChatGPT API call
- modules/RunGPT4Exe.ps1: Executes the GPT-4 executable
- modules/RunInputPlugins.ps1: A plugin system for processing input
- modules/RunOutputPlugins.ps1: A plugin system for processing output
- modules/RunStartPlugins.ps1: A plugin system for processing start messages
- modules/RunSystemPlugins.ps1: A plugin system for processing system messages

The plugin system is based on separate modules for different types of plugins:

1. RunStartPlugins.ps1: Searches for and runs start plugins in the "plugins" folder. Example:
   - plugins/1_Sample_Start_Format.ps1: A sample start plugin that leaves the start message unchanged

2. RunInputPlugins.ps1: Searches for and runs input plugins in the "plugins" folder. Example:
   - plugins/1_Sample_Input_Format.ps1: A sample input plugin that leaves the prompt unchanged

3. RunSystemPlugins.ps1: Searches for and runs system plugins in the "plugins" folder. Example:
   - plugins/1_Sample_System_Format.ps1: A sample system plugin that leaves the system message unchanged

4. RunOutputPlugins.ps1: Searches for and runs output plugins in the "plugins" folder. Example:
   - plugins/1_SessionLog_Output_Format.ps1: A sample output plugin that logs the output to a session file

Options.ps1 allows users to customize various settings such as the model, pause behavior, seed value, loop count, API key, OpenAI model selection, and debugging options.

Please refer to the source code for the full implementation of each plugin and module.
