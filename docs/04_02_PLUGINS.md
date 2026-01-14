# Creating and Loading Plug-Ins

The NextGen Framework's main advancement is its extensibility, so using NGIAB in its base state may prove a bit limiting. This is where support for **plug-ins** comes in, allowing you to import any combination of BMI modules you prefer into NGIAB and freely distribute your own plug-ins to the hydrology community.

> Familiarity with [`dev.sh`](./04_01_DEV_SCRIPT.md) is strongly recommended before working with plug-ins.

## Importing Plug-Ins

Importing an existing plug-in is easy: just drag the plug-in folder into the `/plugins/` folder, then use `dev.sh` to rebuild your local development image with all current plug-ins.

## Creating Plug-Ins

NGIAB-CloudInfra uses [Planks for Docker](https://github.com/Sheargrub/planks_docker) as its plug-in framework. Planks can best be thought of as small Dockerfile segments that will be additively inserted into the main Dockerfile, similarly to wooden planks being laid into a dock. This approach enables a high degree of flexibility, enabling BMI modules to be freely imported and built in the same manner as a standard Dockerfile while remaining distributable as standalone packages.

To create a new plug-in, `dev.sh` can be used to initialize a new plug-in. This plug-in will be pre-populated with plankfiles for each of the possible plankgaps where plug-in data can be loaded, along with `plank_conf.yml`, which should be edited to provide a unique plug-in name. These plankfiles are standard text files that can be edited just like a Dockerfile, and their contents will be segmented into their own build stage.

> Note that specifying build stages in plankfiles is an anti-pattern, and for NGIAB's purposes, it will likely cause conflicts due to the dynamic generation of new build stages. All other functionality of Dockerfiles should be available as normal.

> When referencing local entries in your filesystem, relative paths from `/docker/` are strongly preferred.

### Plankgaps

Plankgaps are the set positions in the NGIAB Dockerfile where code from plankfiles can be inserted. Each plankfile will append its code within the plankgap that has a matching name in the Dockerfile. The available plankgaps are as follows:

- `after_base`: Runs after the initial `base` stage. Best used to define environment variables or import global dependencies.
- `after_build_base`: Runs after the `build_base` stage. Best used to import build dependencies.
- `after_troute_build`: Runs after the `troute_build` stage. Best used to build Python packages, since the relevant build tools are loaded at this time.
- `after_ngen_build`: Runs after the `ngen_build` stage. Best used to build modules written in C, C++, or other languages that don't interface with the Python environment.
- `after_restructure_files`: Runs after the `restructure_files` stage. Should be used to set up directories and permissions immediately prior to the `dev` stage.
- `after_prefile`: Runs after the `prefinal` stage. Should be used to move your build files to their final locations in the finished image.

Note that removing plankfiles you don't need is strongly recommended before sharing your plug-in, as excess plankfiles will create unwanted clutter in the resulting Dockerfile.