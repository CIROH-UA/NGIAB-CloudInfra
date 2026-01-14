# Using `dev.sh`

Whereas `guide.sh` is the all-in-one script for running NGIAB, `dev.sh` is the all-in-one script for modifying it. `dev.sh` allows you to generate new plug-in folders, specify custom sources for ngen or t-route, and use these customized settings to build a local development image of NGIAB with everything you'd like to include.

For ease of reference, `dev.sh` includes a "Help" option in its initial menu. This page's contents largely mirror the contents of that help menu, with each section explaining a facet of `dev.sh`'s functionality.

## Rebuild local image
This option rebuilds a local development image based on your provided plugins and other configuration settings, which are stored in `conf_dev.yml`. Note that this configuration file is generated automatically when loading `dev.sh` for the first time, and shouldn't need to be manually edited in most cases.

## Create a new plug-in
This option creates a new plug-in from a template in `/plugins/`. For more information on developing plug-ins, please see ["Creating and Loading Plug-Ins"](./04_02_PLUGINS.md).

Note that once plug-ins are added to the plug-ins folder, you'll need to rebuild the local image before those changes are reflected in your development build.

## Set NextGen development repo
Sets the source repository that your development build will use for the NextGen framework. This is mostly useful for development of the framework itself, allowing you to test out alternative branches.

## Set T-Route development repo
Sets the source repository that your development build will use for T-Route. This is mostly useful for development of the routing library itself, allowing you to test out alternative branches.