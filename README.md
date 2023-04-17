# AutoGPT_PS

AutoGPT_PS is a PowerShell script that runs GPT-4, processes user input, and returns generated responses. The script includes a plugin system that allows for easy customization of input processing, output formatting, and more.

## Usage

1. Download the AutoGPT_PS repository.
2. Place the GPT-4 model file (in .bin format) in the same directory as the AutoGPT.ps1 script.
3. Run the AutoGPT.ps1 script.

## Options

1. **Change Model**: Allows selection of a .bin file to use for GPT4All. Example: `gpt4all-lora-quantized.bin`.
2. **Toggle Pause**: Enables or disables pausing after every iteration of the main loop. Default value: `y` (pause).
3. **Change Seed**: Sets the seed value for GPT4All. Default value: `` (use the first generated seed) ('0' will use a random seed everytime.).
4. **Change Loop Count**: Sets the number of loops for the main loop. Default value: `10` (ten loops).
5. **Toggle Use ChatGPT**: Enables or disables the use of the OpenAI Chat API. Default value: `False` (disabled).
6. **Set OpenAI Key**: Sets the OpenAI API key.
7. **OpenAI Models**: Allows selection of an OpenAI model from the available options: `text-davinci-003`, `gpt-3.5-turbo`, and `gpt-4`. Default value: `text-davinci-003`.
8. **Turn On Debug**: Enables or disables debug messages at most steps of the scripts. Default value: `False` (disabled).

To update these options, select "y" when it prmpts "Do you want to check options? (y)es/(n)o:" at the start.

## Examples

In the "examples" folder there are the examples for a run using each model.  GPT4ALL is almost useless, but a better plugin that formats for GPT4All might help.

## Creating Plugins

AutoGPT_PS includes a plugin system that allows for easy customization of input processing, output formatting, and more. There are three types of plugins:

1. Start plugins
2. Input plugins
3. Output plugins

Each plugin should be a PowerShell script with a specific naming convention: `N_Name_PluginType_Format.ps1`, where `N` is an integer, `Name` is a descriptive name for the plugin, and `PluginType` is one of the three types: `Start`, `Input`, or `Output`.

To create a new plugin, simply create a new PowerShell script with the appropriate naming convention and place it in the "plugins" folder. The AutoGPT_PS script will automatically discover and run the plugins in the specified order.

For examples of each plugin type, see the scripts provided in the "plugins" folder.
