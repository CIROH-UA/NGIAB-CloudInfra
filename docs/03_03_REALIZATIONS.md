# Realization Files

Realization files define the arrangement of models that the NextGen framework will use to execute model runs.
These realizations are written in [JSON format](https://www.json.org/json-en.html).

> This section is heavily referenced from [the NextGen framework's documentation on the topic](https://noaa-owp.github.io/ngen/md_doc_2_r_e_a_l_i_z_a_t_i_o_n___c_o_n_f_i_g_u_r_a_t_i_o_n.html).

## Top-level keys

The realization configuration must contain three first-level object keys: `global`, `time`, and `catchments`.
NGIAB model run configurations will often also include the `routing` and `metadata` keys.

The optional `output_root` key should not be used with NGIAB, as it will interfere with retrieving model outputs from the container.

## `global` key-value object

The `global` key-value object defines the global formulation and forcings for the model run.

```JSON
"global": {
  "formulations": [
    {
        "name": "bmi_c",
        "params": {
            "maxsmc": 0.439,
            "wltsmc": 0.066,
            "satdk": 0.00000338
        /* --- continued --- */
        }
    }
  ],
  "forcing": {
      "file_pattern": ".*{{id}}.*.csv",
      "path": "./data/forcing/"
  }
},  
```

### `formulations`

Contains a list of formulation key-value objects that define the default required formulations. Each formulation object has the following keys:
- `name`: Defines the name value for the type of BMI module being referenced.
    - Valid values include `bmi_c++`, `bmi_c`, `bmi_fortran`, `bmi_python`, and `bmi_multi`.
- `params`: A key-value object. Its contents will vary depending on the target model.

The parameters of a formulation differ depending on its contents. For model-specific parameters, see "[Included Models](./03_04_MODELS.md)".

- Required
    - `model_type_name`: A unique string identifying the underlying model type.
    - `main_output_variable`: The name of the framework variable that will store the formulation's `get_response()` function.
        - It is not responsible for catchment output files, which are controlled by the `output_variable` parameter.
- Required for single-module formulations
    - `init_config`: The path for the BMI initialization for the model. The substring `{{id}}` will be substituted for the catchment ID, allowing for per-catchment configurations.
    - `uses_forcing_file`: A boolean indicating whether the underlying BMI model is written to read input forcing data from a forcing file.
- Conditionally required
    - `forcing_file`: A string path to the forcing data file for the model. The substring `{{id}}` will be substituted for the catchment ID, allowing for per-catchment configurations.
        - Only required if `uses_forcing_file` is enabled.
    - `registration_function`: Name of the pointer registration function in the external module. Defaults to `register_bmi` if unspecified.
        - Only meaningful for `bmi_c` formulations.
        - Only required if `register_bmi` is not the pointer registration function.
    - `library_file`: Path to the library file for the BMI model.
        - Non-meaningful for `bmi_python` formulations, which depend on the current Python environment.
        - Required for all other formulations targeting NGIAB, as NGIAB relies strictly on external BMI libraries.
        - For paths to library files included in NGIAB, see "[Included Models](./03_04_MODELS.md)".
    - `python_type`: The name of the Python class representing the BMI model, including the package name.
        - Only required for `bmi_python` formulations, and non-meaningful for other types.
        - For types of included Python models, see "[Included Models](./03_04_MODELS.md)".
- Optional
    - `variables_names_map`: Specifies a mapping of model inputs/outputs to aliases that act as framework variables.
        - Helpful for instructing the framework on how to provide certain inputs to a model, such as forcing data or outputs from other submodules in `bmi_multi` formulations.
    - `model_params`: Specifies static or dynamic parameters that will be passed to the model as model variables.
        - Note that only the hydrofabric is currently supported as a source of dynamic parameters.
            - For other forms of data passing, see `variables_names_map`.
        - Dynamic parameters should be specified as key-value objects with the following contents:
            - `source`: The source of the parameter. NextGen currently only supports `"hydrofabric"` as a source.
            - `from`: The type of data to pass from the source, such as `"area_sqkm"`. <!-- TODO: Where are the options for this defined? -->
        - Non-meaningful for `bmi_multi` formulations.
    - `output_variables`: A list of strings indicating the set of output variables to include in the realization's `get_output_line_for_timestep()` function.
        - Defaults to the output of the model's `get_output_var_names()` function if unspecified.
        - In `bmi_multi` formulations, this should not be specified for submodules.
    - `output_header_fields`: A list of strings used as a header for the realization's printed output. In practice, this should be formatted versions of the variable names from `output_variables`.
        - Defaults to the value of `output_variables` if unspecified.
        - In `bmi_multi` formulations, this should not be specified for submodules.
    - `allow_exceed_end_time`: Specifies whether a model is allowed to execute `Update` calls beyond its end time (or the latest forcing data entry). Defaults to `false` if unspecified.
    - `fixed_time_step`: Specifies whether a model has a fixed time-step size. Defaults to `true` if unspecified.
- For `bmi_multi` formulations
    - `modules`: A list of submodules. Each submodule should be specified as a formulation key-value object.

> This section provides only a brief reference for writing formulations in NGIAB. For more specific technical details, please reference the [NextGen framework documentation](https://noaa-owp.github.io/ngen/md_doc_2_b_m_i___m_o_d_e_l_s.html) on external BMI models.

### `forcing`

The contents of this key-value object will depend on the format of the provided forcings.

- **NetCDF files**
    - `path`: Points to the relative path of the forcings file.
    - `provider`: Should be set to `"NetCDF"`.
- **CSV files**
    - `file_pattern`: The file pattern for the forcing files. Should include the substring `{{id}}`, which will be substituted for the catchment ID.
    - `path`: Points to the relative path of the forcings directory.

## `time` key-value object

The `time` key-value object simply contains three keys:
- `start_time`: Defines the UTC start time of the simulation. Must be in the form `yyyy-mm-dd hh:mm:ss`.
- `end_time`: Defines the UTC end time of the simulation. Must be in the form `yyyy-mm-dd hh:mm:ss`.
- `output_interval`: Defines the time interval on which model outputs are generated. Written in seconds.

```JSON
"time": {
    "start_time": "2015-12-01 00:00:00",
    "end_time": "2015-12-30 23:00:00",
    "output_interval": 3600
},
```

## `catchments` key-value object
The `catchments` key-value object must contain a list of all catchment object keys that will have defined formulations.

## `routing` key-value object
NGIAB model runs should always use the following routing object to ensure that `troute.yaml` is accessible within the container.
```JSON
"routing": {
    "t_route_config_file_with_path": "/ngen/ngen/data/calibration/troute.yaml",
    "t_route_connection_path": ""
},
```

<!-- TODO: T-Route configuration info? -->

## `metadata` key-value object
This object is generated by certain tools, such as [Data Preprocess](https://github.com/CIROH-UA/ngiab_data_preprocess), to provide contextual information regarding the model run directory.
While NGIAB doesn't actively use this metadata, it may be helpful in determining how a model run directory was created.