Param(
    [string]$FunctionName,
    [array]$ArgumentList
)
function GetFullName {
    return "Output DallE Prompts Plugin"
}

function Run {
    Param(
        [string]$prompt,
        [string]$response,
        [string]$system
    )

    Debug -debugText "$(GetFullName) Running"

    # Check for [Dalle]..[/dalle] tags and process them
    $regexPattern = '(?i)\<Dalle(.*?)\>(.*?)\</dalle\>'
    $regex = [regex]::new($regexPattern)
    $matches = $regex.Matches($response)

    foreach ($match in $matches) {
        $content = $match.Groups[2].Value
        $options = $match.Groups[1].Value.Trim()
        $optionsRegex = "(?i)dest='(.*?)'"
        $optionsMatch = [regex]::Match($options, $optionsRegex)
        if ($optionsMatch.Success) {
            $dest = $optionsMatch.Groups[1].Value
        } else {
            $dest = ""
        }

        if ($settings.UseDalleTextToImage) {
            $dalleResponse = Invoke-DallEAPI -prompt $content

            if ($dest -ne "") {
                Save-DalleImages -prompt $content -dalleResponse $dalleResponse -optionsFilename $dest
            } else {
                Save-DalleImages -prompt $content -dalleResponse $dalleResponse
            }
        } elseif ($settings.UseStableDiffTextToImage) {
            # Load plugin properties
            Start-Sleep -Seconds 1
            $props = GetProperties

            # Add Stable Diffusion Code Here
            $dalleResponse = Invoke-StableDiff `
                -prompt $content `
                -filename $dest `
                -steps (GetProperty -properties $props -propertyName "StableDiffusion_steps") `
                -enable_hr (GetProperty -properties $props -propertyName "StableDiffusion_enable_hr") `
                -denoising_strength (GetProperty -properties $props -propertyName "StableDiffusion_denoising_strength") `
                -firstphase_width (GetProperty -properties $props -propertyName "StableDiffusion_firstphase_width") `
                -firstphase_height (GetProperty -properties $props -propertyName "StableDiffusion_firstphase_height") `
                -hr_scale (GetProperty -properties $props -propertyName "StableDiffusion_hr_scale") `
                -hr_upscaler (GetProperty -properties $props -propertyName "StableDiffusion_hr_upscaler") `
                -hr_second_pass_steps (GetProperty -properties $props -propertyName "StableDiffusion_hr_second_pass_steps") `
                -hr_resize_x (GetProperty -properties $props -propertyName "StableDiffusion_hr_resize_x") `
                -hr_resize_y (GetProperty -properties $props -propertyName "StableDiffusion_hr_resize_y") `
                -styles (GetProperty -properties $props -propertyName "StableDiffusion_styles") `
                -seed (GetProperty -properties $props -propertyName "StableDiffusion_seed") `
                -subseed (GetProperty -properties $props -propertyName "StableDiffusion_subseed") `
                -subseed_strength (GetProperty -properties $props -propertyName "StableDiffusion_subseed_strength") `
                -seed_resize_from_h (GetProperty -properties $props -propertyName "StableDiffusion_seed_resize_from_h") `
                -seed_resize_from_w (GetProperty -properties $props -propertyName "StableDiffusion_seed_resize_from_w") `
                -sampler_name (GetProperty -properties $props -propertyName "StableDiffusion_sampler_name") `
                -batch_size (GetProperty -properties $props -propertyName "StableDiffusion_batch_size") `
                -n_iter (GetProperty -properties $props -propertyName "StableDiffusion_n_iter") `
                -cfg_scale (GetProperty -properties $props -propertyName "StableDiffusion_cfg_scale") `
                -width (GetProperty -properties $props -propertyName "StableDiffusion_width") `
                -height (GetProperty -properties $props -propertyName "StableDiffusion_height") `
                -restore_faces (GetProperty -properties $props -propertyName "StableDiffusion_restore_faces") `
                -tiling (GetProperty -properties $props -propertyName "StableDiffusion_tiling") `
                -negative_prompt (GetProperty -properties $props -propertyName "StableDiffusion_negative_prompt") `
                -eta (GetProperty -properties $props -propertyName "StableDiffusion_eta") `
                -s_churn (GetProperty -properties $props -propertyName "StableDiffusion_s_churn") `
                -s_tmax (GetProperty -properties $props -propertyName "StableDiffusion_s_tmax") `
                -s_tmin (GetProperty -properties $props -propertyName "StableDiffusion_s_tmin") `
                -s_noise (GetProperty -properties $props -propertyName "StableDiffusion_s_noise") `
                -override_settings (GetProperty -properties $props -propertyName "StableDiffusion_override_settings") `
                -override_settings_restore_afterwards (GetProperty -properties $props -propertyName "StableDiffusion_override_settings_restore_afterwards") `
                -script_args (GetProperty -properties $props -propertyName "StableDiffusion_script_args") `
                -sampler_index (GetProperty -properties $props -propertyName "StableDiffusion_sampler_index") `
                -script_name (GetProperty -properties $props -propertyName "StableDiffusion_script_name")

            # Stop Stable Diffusion Code Here
        } else {
            Write-Host "Not Implemented" -ForegroundColor Red
        }

       

        $response = $response.Replace($match.Value, "")
    }

    return $response
}

function GetProperties {
    $setName = GetFullName
    $propertiesFromFile = GetPluginPropertiesFromFile -pluginName $setName

    $defaultProperties = @(
        @{
            Name  = "Enabled"
            Value = $false
            Type  = "Boolean"
        },
        @{
            Name  = "Order"
            Value = 99
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_png_info_url"
            Value = "/sdapi/v1/png-info"
            Type  = "String"
        },
        
        @{
            Name  = "StableDiffusion_enable_hr"
            Value = $false
            Type  = "Boolean"
        },
        @{
            Name  = "StableDiffusion_denoising_strength"
            Value = 0
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_firstphase_width"
            Value = 0
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_firstphase_height"
            Value = 0
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_hr_scale"
            Value = 2
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_hr_upscaler"
            Value = ""
            Type  = "String"
        },
        @{
            Name  = "StableDiffusion_hr_second_pass_steps"
            Value = 0
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_hr_resize_x"
            Value = 0
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_hr_resize_y"
            Value = 0
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_prompt"
            Value = ""
            Type  = "String"
        },
        @{
            Name  = "StableDiffusion_styles"
            Value = ""
            Type  = "String"
        },
        @{
            Name  = "StableDiffusion_seed"
            Value = -1
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_subseed"
            Value = -1
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_subseed_strength"
            Value = 0
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_seed_resize_from_h"
            Value = -1
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_seed_resize_from_w"
            Value = -1
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_sampler_name"
            Value = ""
            Type  = "String"
        },
        @{
            Name  = "StableDiffusion_batch_size"
            Value = 1
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_n_iter"
            Value = 1
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_steps"
            Value = 50
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_cfg_scale"
            Value = 7
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_width"
            Value = 512
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_height"
            Value = 512
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_restore_faces"
            Value = $false
            Type  = "Boolean"
        },
        @{
            Name  = "StableDiffusion_tiling"
            Value = $false
            Type  = "Boolean"
        },
        @{
            Name  = "StableDiffusion_negative_prompt"
            Value = ""
            Type  = "String"
        },
        @{
            Name  = "StableDiffusion_eta"
            Value = 0
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_s_churn"
            Value = 0
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_s_tmax"
            Value = 0
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_s_tmin"
            Value = 0
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_s_noise"
            Value = 1
            Type  = "Int"
        },
        @{
            Name  = "StableDiffusion_override_settings"
            Value = ""
            Type  = "String"
        },
        @{
            Name  = "StableDiffusion_override_settings_restore_afterwards"
            Value = $true
            Type  = "Boolean"
        },
        @{
            Name  = "StableDiffusion_script_args"
            Value = ""
            Type  = "String"
        },
        @{
            Name  = "StableDiffusion_sampler_index"
            Value = "Euler"
            Type  = "String"
        },
        @{
            Name  = "StableDiffusion_script_name"
            Value = ""
            Type  = "String"
        }
    )


    if ($propertiesFromFile -ne $null) {
        $updatedProperties = MergeAndSaveProperties -pluginName $setName -defaultProperties $defaultProperties -loadedProperties $propertiesFromFile
        return $updatedProperties
    }

    return $defaultProperties
}

function GetConfigurable {
    return "True"
}

function GetPluginType {
    return 3 # Output Plugin
}

# ////////////////////////////////////////////////////////////
# Common Code do not change unles you want to break something.
# ////////////////////////////////////////////////////////////

switch ($FunctionName) {
    "GetFullName" { return GetFullName }
    "GetConfigurable" { return GetConfigurable }
    "Run" { return Run -prompt $ArgumentList[0] -response $ArgumentList[1] -system $ArgumentList[2]}
    "GetPluginType" { return GetPluginType }
    "GetProperties" { return GetProperties }
    default { Write-Host "Invalid function name" }
}

