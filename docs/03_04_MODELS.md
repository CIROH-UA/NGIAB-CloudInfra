# Included Models

<!-- TODO: Not currently happy with the depth of these explanations. I need to learn more, but resources are slim at times... -->
<!-- TODO: Provide extended explanations of realization configs -->

## Simple Logical Tautology Handler (SLOTH)

> *GitHub: [NOAA-OWP/SLoTH](https://github.com/NOAA-OWP/SLoTH)*

SLoTH offers the simplest possible behavior for a model: each input will be returned directly as an output.
While largely useless on its own, it offers necessary utilities for supporting complex formulations of multiple BMI modules.
For example, it can be used to feed constant forcing values into a model or echo output values between timesteps.

Library file path: `/dmod/shared_libs/libslothmodel.so.1.0.0`

## Conceptual Functional Equivalent (CFE)

> *GitHub: [NOAA-OWP/CFE](https://github.com/NOAA-OWP/CFE)*

This simplified conceptual model by Fred Ogden is designed to be functionally equivalent to earlier versions of the National Water Model.
It offers a streamlined solution to modeling runoff generation, vadose zone dynamics, and groundwater behavior.

Library file path: `/dmod/shared_libs/libcfebmi.so.1.0.0`

## Potential Evapotranspiration (PET)

> *GitHub: [NOAA-OWP/evapotranspiration](https://github.com/NOAA-OWP/evapotranspiration)*

This module bundles several functions for estimating potential evapotranspiration, or the upper bound for the amount of water
that will be passively evaporated from soil given sufficient supply.

Library file path: `/dmod/shared_libs/libpetbmi.so.1.0.0`

## NOAH-OWP-Modular

> *GitHub: [NOAA-OWP/NOAH-OWP-Modular](https://github.com/NOAA-OWP/NOAH-OWP-Modular)*

NOAH-OWP-Modular is a generalized refactoring of Noah-MP, a land surface model.

Library file path: `/dmod/shared_libs/libsurfacebmi.so`

## TOPMODEL

> *GitHub: [NOAA-OWP/TOPMODEL](https://github.com/NOAA-OWP/TOPMODEL)*

TOPMODEL is a watershed model focused on interactions between groundwater and surface water.

Library file path: `/dmod/shared_libs/libtopmodelbmi.so.1.0.0`

## Long Short-Term Memory (LSTM)

> *GitHub: [CIROH-UA/lstm](https://github.com/CIROH-UA/lstm)*  
> *Fork developed by [Jonathan Frame](https://github.com/jmframe)*

LSTM networks are a type of recurrent neural network used in deep learning.
This LSTM module is specifically tailored for generalized streamflow prediction within CONUS.

Python class: `lstm.bmi_LSTM` <!-- TODO: verify -->

## Soil Moisture Profiles

> *GitHub: [NOAA-OWP/SoilMoistureProfiles](https://github.com/NOAA-OWP/SoilMoistureProfiles)*

This module packages several schemes to model soil moisture, including ones specifically tailored to CFE and TOPMODEL.

*Temporarily unavailable due to an [upstream issue](https://github.com/CIROH-UA/ngen/issues/14).*

## Soil Freeze-Thaw Model

> *GitHub: [NOAA-OWP/SoilFreezeThaw](https://github.com/NOAA-OWP/SoilFreezeThaw)*

This model simulates heat transfer in soil, enabling modeling of freeze/thaw cycles in water.
Its underlying methodology is comparable to NOAH-MP (see NOAH-OWP-Modular above).

*Temporarily unavailable due to an [upstream issue](https://github.com/CIROH-UA/ngen/issues/14).*

# T-Route

> *GitHub: [CIROH-UA/t-route](https://github.com/CIROH-UA/t-route)*
> *Fork maintained by [Josh Cunningham](https://github.com/joshcu)*

T-Route is a routing model used for solving streamflow networks.
Compared to the other models packaged with NGIAB, T-Route is uniquely central because it sits at the core of all NextGen model runs.
As such, instead of invoking it via a formulation, it should be configured in `troute.yaml`.
<!-- TODO: This is inferred from context! More information needed. -->

NGIAB includes a customized fork of T-Route maintained by CIROH.
It retains all functionality from the canonical version of T-Route while enhancing it with major performance optimizations.

# Adding additional models

Unfortunately, NGIAB does not currently offer native support for adding additional models.
Investigation on how best to provide this functionality is underway.


In the meantime, you will need to build a new version of the NGIAB-CloudInfra container that incorporates your desired model.
For more information, please see ["Building the NGIAB Docker container"](./04_BUILDING.md).