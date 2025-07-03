# Getting Started

NextGen In A Box is a simple, straightforward way to begin integrating the NextGen framework into your research, creating a pathway to connect your work with other models and easily implement it in operational contexts.

### What is the NextGen framework?
The Next Generation Water Resources Modeling Framework, most frequently referred to as NextGen, is a hydrologic modeling framework that forms the core for upcoming modern versions of the National Water Model. NextGen is highly modular and model-agnostic, which allows it to easily interoperate with hydrological models of any kind via the [Basic Model Interface](https://csdms.colorado.edu/wiki/BMI) (BMI) standard.

Unfortunately, while NextGen is extremely powerful, it is also extremely laborious to configure and deploy. NGIAB solves this problem via containerization.

> For a more detailed summary, click here: https://docs.ciroh.org/docs/products/ngiab/intro/what-is

### What is containerization?

Containerization is a type of virtualization technology, which means that it creates simulated operating systems on top of your standard operating system. Compared to traditional virtual machines, which act as standalone units, containers save on storage and memory by sharing key components of the operating system between containers.

These containers also come with two other benefits: they offer a consistent environment through which software can be run, and they can be easily be reproduced from "image" files, which save the container's state in its entirety. NGIAB takes advantage of these states by containerizing the NextGen framework, entirely mitigating its difficult setup process.

## Using NGIAB

If you're completely new to the NGIAB, the **[NGIAB 101 training module](https://docs.ciroh.org/training-NGIAB-101/)** is the best place to get started. It contains everything you need to get acquainted with both NGIAB itself and its surrounding ecosystem of helpful tools.

Otherwise, the [next section](./02_INSTALL.md) of this documentation offers a quick refresher on how to start running NGIAB.