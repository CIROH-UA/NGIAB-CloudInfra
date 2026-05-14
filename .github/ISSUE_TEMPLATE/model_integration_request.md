---
name: Model Integration Checklist for NGIAB
about: This form would be for the new model that will be integrated with NGIAB.
title: ''
labels: 'model-integration, needs-review, NGIAB'
assignees: ''

---

**1. Contributor Information**
- Name:
- Email:
- Institution/Organization:
- GitHub Username:
- Model Name:
- Model Version:
- Date Submitted:

---

**2. Model Overview**

#### Basic Information

- [ ] **Model Description:** (Provide a brief description of what the model does)
  
  > [Your description here]

- [ ] **Model Type:** (Check all that apply)
  - [ ] Hydrologic Process Model
  - [ ] Routing Model
  - [ ] Forcing Engine
  - [ ] Calibration Tool
  - [ ] Post-processing Tool
  - [ ] Other: _______________

- [ ] **Programming Language(s):**
  - [ ] C/C++
  - [ ] Fortran
  - [ ] Python
  - [ ] Other: _______________

- [ ] **Primary Use Case:**
  
  > [Describe the intended use case]

---

**3. Technical Requirements**

#### BMI Compliance

- [ ] **BMI Implementation:** Does your model implement the Basic Model Interface (BMI)?
  - [ ] Yes - Full BMI implementation
  - [ ] Partial - Specify which functions: _______________
  - [ ] No - Plan to implement: _______________

- [ ] **BMI Language Binding:**
  - [ ] C
  - [ ] C++
  - [ ] Fortran
  - [ ] Python
  - [ ] Other: _______________

#### Dependencies

- [ ] **Required Libraries:** (List all required libraries and their versions)
  
  > Example:
  > - NetCDF >= 4.8.0
  > - HDF5 >= 1.12.0
  > - MPICH >= 3.4

- [ ] **System Dependencies:** (List any system-level requirements)
  
  > [List here]

- [ ] **Python Packages:** (If applicable, list required Python packages)
  
  > [Requirements.txt format preferred]

#### Build System

- [ ] **Build System Used:**
  - [ ] CMake
  - [ ] Make
  - [ ] Autotools
  - [ ] Python setuptools
  - [ ] Other: _______________

- [ ] **Build Instructions Provided:**
  - [ ] Yes - Link: _______________
  - [ ] Need assistance

- [ ] **Compilation Flags/Options:** (List any special compilation requirements)
  
  > [Flags here]

---

**4. Code Repository**

#### Source Code

- [ ] **Repository URL:**
  
  > [GitHub/GitLab URL]

- [ ] **Repository Access:**
  - [ ] Public
  - [ ] Private (requires access request)

- [ ] **License:**
  - [ ] Open Source License (Specify): _______________
  - [ ] Proprietary (explain restrictions): _______________

- [ ] **Branch/Tag for Integration:**
  
  > [Specify stable branch or release tag]

#### Documentation

- [ ] **Documentation Available:**
  - [ ] README with basic usage
  - [ ] Installation guide
  - [ ] API/BMI documentation
  - [ ] Configuration file documentation
  - [ ] Example/tutorial
  - [ ] Scientific documentation/paper

- [ ] **Documentation Links:**
  
  > [Provide links]

---

**5. Configuration & Data Requirements**

#### Input Requirements

- [ ] **Input File Formats:** (List all required input formats)
  
  > Example:
  > - NetCDF (.nc)
  > - CSV (.csv)
  > - Binary (.bin)

- [ ] **Required Input Variables:** (List all required input variables with units)
  
  > Example:
  > - Precipitation (mm/hr)
  > - Temperature (deg C)
  > - Soil moisture (-)

- [ ] **Sample Input Data Provided:**
  - [ ] Yes - Link: _______________
  - [ ] No - Can provide upon request

#### Output Specifications

- [ ] **Output File Formats:**
  
  > [List formats]

- [ ] **Output Variables:** (List all output variables with units)
  
  > [List here]

- [ ] **Output Frequency:**
  - [ ] Sub-hourly (specify): _______________
  - [ ] Hourly
  - [ ] Daily
  - [ ] Other: _______________

#### Configuration Files

- [ ] **Configuration File Format:**
  - [ ] JSON
  - [ ] YAML
  - [ ] INI
  - [ ] Custom text format
  - [ ] Other: _______________

- [ ] **Sample Configuration Provided:**
  - [ ] Yes - Link: _______________
  - [ ] No - Can provide

- [ ] **Configuration Parameters Documented:**
  - [ ] Yes
  - [ ] Partial
  - [ ] No

---

**6. Testing & Validation**

#### Testing Status

- [ ] **Unit Tests Available:**
  - [ ] Yes - Coverage: _____%
  - [ ] No - Plan to add

- [ ] **Integration Tests Available:**
  - [ ] Yes
  - [ ] No

- [ ] **Test Data Included:**
  - [ ] Yes - Link: _______________
  - [ ] No - Can provide

#### Validation

- [ ] **Model Validation Performed:**
  - [ ] Yes - Published results available
  - [ ] Yes - Internal validation only
  - [ ] In progress
  - [ ] Not yet validated

- [ ] **Validation Domain/Region:**
  
  > [Describe where model has been tested]

- [ ] **Performance Metrics:** (If available)
  
  > Example:
  > - NSE: 0.85
  > - RMSE: 2.3 m^3/s
  > - Bias: -5%

---

**7. Container Compatibility**

#### Docker Requirements

- [ ] **Base Image Preference:**
  - [ ] Rocky Linux 9.1 (NGIAB default)
  - [ ] Ubuntu
  - [ ] Alpine
  - [ ] Other: _______________

- [ ] **Special Container Requirements:**
  
  > [List any special needs like GPU support, large memory, specific base images, or changes needed to the Dockerfile]

#### HPC/Singularity Considerations

- [ ] **HPC Compatibility Required:**
  - [ ] Yes
  - [ ] No
  - [ ] Not sure

- [ ] **MPI Support:**
  - [ ] Required
  - [ ] Optional
  - [ ] Not needed

- [ ] **Parallel Execution Support:**
  - [ ] Shared memory (OpenMP)
  - [ ] Distributed memory (MPI)
  - [ ] GPU/CUDA
  - [ ] Serial only

---

**8. Integration Planning**

#### Timeline

- [ ] **Target Integration Date:**
  
  > [Proposed date]

- [ ] **Development Status:**
  - [ ] Production-ready
  - [ ] Beta/testing
  - [ ] Early development
  - [ ] Proof of concept

#### Support & Maintenance

- [ ] **Maintenance Commitment:**
  - [ ] Will maintain long-term
  - [ ] Limited support available
  - [ ] Community maintenance
  - [ ] Unsure

- [ ] **Point of Contact for Technical Questions:**
  - Name:
  - Email:
  - Preferred contact method:

- [ ] **Expected Response Time for Issues:**
  - [ ] Within 24 hours
  - [ ] Within 1 week
  - [ ] Best effort
  - [ ] Other: _______________

#### Collaboration

- [ ] **Open to Collaboration:**
  - [ ] Yes - Open to contributions
  - [ ] Yes - With approval
  - [ ] Prefer to maintain independently

- [ ] **CIROH/NGIAB Team Support Needed:**
  - [ ] BMI implementation assistance
  - [ ] Containerization help
  - [ ] CI/CD pipeline setup
  - [ ] Documentation improvement
  - [ ] Testing framework
  - [ ] Other: _______________

---

**9. Specific NGIAB Integration**

#### Hydrofabric Compatibility

- [ ] **Works with NOAA Hydrofabric:**
  - [ ] Yes - Tested
  - [ ] Should work (not tested)
  - [ ] Requires modifications
  - [ ] Not applicable

- [ ] **Spatial Resolution:**
  - [ ] Catchment-level
  - [ ] Grid-based (specify resolution): _______________
  - [ ] Point-based
  - [ ] Other: _______________
        
- [ ] **Required Input Variables:** (List all required input variables with units)

#### NextGen Framework Integration

- [ ] **Integration Level:**
  - [ ] Core modeling component (replaces/supplements existing formulation)
  - [ ] Pre-processing tool
  - [ ] Post-processing tool
  - [ ] Visualization component
  - [ ] Evaluation tool
  - [ ] Other: _______________

- [ ] **Compatibility with Existing Components:**
  - [ ] CFE
  - [ ] NOAH-OWP-Modular
  - [ ] TOPMODEL
  - [ ] t-route
  - [ ] Other formulations: _______________

#### Data Integration

- [ ] **Data Sources Supported:**
  - [ ] NOAA forcing data
  - [ ] USGS observations
  - [ ] Custom forcing files
  - [ ] Other: _______________

- [ ] **Compatible with NGIAB Data Preprocess Module:**
  - [ ] Yes - Tested
  - [ ] Should be compatible
  - [ ] Requires adaptation
  - [ ] Not applicable

---

**10. Additional Information**

#### Publications

- [ ] **Related Publications:** (List papers, reports, or documentation)
  
  > [Citations here]

#### Known Limitations

- [ ] **Known Issues/Limitations:**
  
  > [Describe any known limitations or constraints]

#### Use Cases

- [ ] **Example Use Cases:**
  
  > [Describe 1-2 specific scenarios where this model would be valuable]

#### Model runtime cost (e.g., time/memory/cpu cost to forward for X catchments and T timesteps) 

#### Additional Notes

> [Any additional information that would be helpful for integration]

---

**11. Checklist Summary**

#### Pre-submission Requirements (Must Complete)

- [ ] Model source code is accessible
- [ ] Basic documentation is available
- [ ] Dependencies are clearly listed
- [ ] Sample configuration file provided
- [ ] Build instructions included
- [ ] License is specified
- [ ] Point of contact identified

#### Recommended (Strongly Encouraged)

- [ ] BMI implementation completed or in progress
- [ ] Test data available
- [ ] Model has been validated in at least one domain
- [ ] Compatible with NGIAB standard formats
- [ ] Documentation includes usage examples

#### Optional (Nice to Have)

- [ ] Unit tests included
- [ ] Published validation results
- [ ] HPC/parallel execution support
- [ ] Integration with existing NGIAB tools demonstrated

---

**12. Submission**

#### I confirm that:

- [ ] All required information above has been provided
- [ ] The model code is ready for review
- [ ] I am authorized to submit this model for integration
- [ ] I agree to provide reasonable support during integration


---
