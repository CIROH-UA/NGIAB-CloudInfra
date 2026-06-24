# NGIAB-NRDS Roadmap

This roadmap frames **NGIAB-NRDS** as part of the existing NGIAB ecosystem in the `CIROH-UA` organization, rather than as a standalone effort.

## Purpose

The current NGIAB ecosystem already separates responsibilities across execution, data preparation, evaluation, visualization, and infrastructure support. NGIAB-NRDS should strengthen those connections by making data and metadata easier to move, discover, reuse, and govern across the ecosystem.

## Ecosystem map

### Core execution

- [`CIROH-UA/NGIAB-CloudInfra`](https://github.com/CIROH-UA/NGIAB-CloudInfra): packaged NGIAB distribution, guide scripts, container build and release workflows
- [`CIROH-UA/ngen`](https://github.com/CIROH-UA/ngen): community NextGen framework implementation
- [`CIROH-UA/t-route`](https://github.com/CIROH-UA/t-route): routing engine used by NGIAB runs

### Data ingress and preparation

- [`CIROH-UA/NGIAB_data_preprocess`](https://github.com/CIROH-UA/NGIAB_data_preprocess): prepares NGIAB-ready run inputs
- [`CIROH-UA/ngen-datastream`](https://github.com/CIROH-UA/ngen-datastream): current closest organizational precedent for research datastream workflows

### Analysis and evaluation

- [`CIROH-UA/ngiab-teehr`](https://github.com/CIROH-UA/ngiab-teehr): post-run evaluation against external datasets
- [`CIROH-UA/ngiab-cal`](https://github.com/CIROH-UA/ngiab-cal): calibration support for NGIAB workflows

### Visualization and access

- [`CIROH-UA/ngiab-client`](https://github.com/CIROH-UA/ngiab-client): data visualization and user-facing output access

### Operations and support

- `NGIAB-CloudInfra` issue templates for model integration and resource requests
- CI/CD workflows in `NGIAB-CloudInfra` for image build, test, and release automation
- CIROH cloud and on-prem resource request flows already represented in `.github/ISSUE_TEMPLATE/`

## Recommended role for NGIAB-NRDS

**Primary role: shared service between preprocess, execution, calibration, and evaluation.**

This role best fits the current ecosystem because NGIAB already has distinct tools for building inputs, running models, evaluating outputs, and visualizing results. NRDS should connect those stages with consistent data contracts, metadata, discovery patterns, and storage conventions instead of duplicating functionality that already lives in adjacent repositories.

## Repo signals that drive priority

The current repository suggests the following roadmap priorities:

- `README.md` already defines the surrounding NGIAB ecosystem and linked repositories.
- `guide.sh`, `runTeehr.sh`, and `viewOnTethys.sh` already orchestrate execution, evaluation, and visualization flows.
- `docs/03_02_RUN_DIRECTORIES.md` defines the run-directory structure that NRDS should align with first.
- Issue templates under `.github/ISSUE_TEMPLATE/` show existing governance patterns for cloud, workshop, on-prem, and model-integration requests.
- `docs/04_BUILDING.md` and `docs/03_04_MODELS.md` highlight current extensibility gaps, so the roadmap should prioritize interface stability before advanced expansion.

## Roadmap workstreams

### 1. Data interfaces

- Align NRDS with the NGIAB run-directory format.
- Define canonical metadata, file contracts, and versioning rules for inputs and outputs.
- Integrate first with preprocess and datastream-oriented repositories.

### 2. Execution integration

- Make NRDS-compatible datasets directly usable from the core NGIAB workflow.
- Support clean handoff into container execution, realization files, and routing configuration.

### 3. Post-run products

- Standardize how outputs are published for evaluation, calibration, and visualization.
- Make run artifacts traceable and reusable across downstream tools.

### 4. Platform operations

- Define storage, permissions, lifecycle, and environment-promotion patterns.
- Reuse existing CI/CD and support workflows where possible.

### 5. User experience

- Provide onboarding, examples, and training paths tied to existing NGIAB docs.
- Support self-service workflows for common research and workshop use cases.

## Phase roadmap

### Phase 1: Foundation

- Clarify NRDS scope and decision boundaries.
- Inventory existing repositories, interfaces, owners, and gaps.
- Define the canonical metadata model and storage contract for NGIAB run data.

**Exit criteria**
- Agreed NRDS scope statement
- Initial interface inventory
- Approved metadata and artifact model

### Phase 2: Core integrations

- Integrate first with `ngen-datastream`, `NGIAB_data_preprocess`, and `NGIAB-CloudInfra`.
- Establish an end-to-end ingest-to-run workflow.
- Ensure NGIAB guide-driven execution can consume NRDS-managed assets with minimal manual handling.

**Exit criteria**
- Working ingest-to-run path
- Documented handoff from preprocess to execution
- Basic validation for required metadata and file layout

### Phase 3: Analysis ecosystem

- Integrate outputs with `ngiab-teehr`, `ngiab-cal`, and `ngiab-client`.
- Standardize how downstream tools discover outputs, metadata, and provenance.
- Enable reuse of prior runs for comparison, calibration, and visualization.

**Exit criteria**
- Shared output-discovery pattern
- Provenance attached to downstream products
- Documented downstream integration examples

### Phase 4: Productization

- Formalize governance, releases, operational support, and ownership.
- Add user-facing documentation, templates, and training.
- Track adoption, friction points, and ecosystem-level feedback.

**Exit criteria**
- Published support and governance process
- Stable release workflow
- Usage and feedback metrics in place

## Initial roadmap backlog

| Objective | Owning repo | Dependency repos | User value | Milestone | Owner | Status |
| --- | --- | --- | --- | --- | --- | --- |
| Define NRDS scope and responsibilities against existing NGIAB components | NGIAB-NRDS | NGIAB-CloudInfra, ngen-datastream | Reduces overlap and design ambiguity | Phase 1 | TBD | proposed |
| Align NRDS artifact model with the NGIAB run-directory structure | NGIAB-NRDS | NGIAB-CloudInfra, NGIAB_data_preprocess | Makes prepared datasets execution-ready | Phase 1 | TBD | proposed |
| Publish required metadata and file-contract specification for runs | NGIAB-NRDS | NGIAB-CloudInfra, ngen-datastream | Improves reproducibility and automation | Phase 1 | TBD | proposed |
| Support ingest-to-run handoff from preprocess/datastream tools into NGIAB execution | NGIAB-NRDS | NGIAB_data_preprocess, ngen-datastream, NGIAB-CloudInfra | Shortens setup time for model runs | Phase 2 | TBD | proposed |
| Enable guide-script and container workflows to reference NRDS-managed assets | NGIAB-CloudInfra | NGIAB-NRDS, ngen, t-route | Makes NRDS useful in the main user path | Phase 2 | TBD | proposed |
| Standardize output publication for evaluation and calibration workflows | NGIAB-NRDS | ngiab-teehr, ngiab-cal | Makes outputs easier to compare and reuse | Phase 3 | TBD | proposed |
| Support output discovery and provenance for visualization clients | NGIAB-NRDS | ngiab-client, ngiab-teehr | Improves access to trustworthy results | Phase 3 | TBD | proposed |
| Reuse CIROH support and request patterns for storage/access governance | NGIAB-CloudInfra | NGIAB-NRDS | Lowers operational friction | Phase 4 | TBD | proposed |
| Publish docs, examples, and training for common NRDS-backed workflows | NGIAB-NRDS | NGIAB-CloudInfra, docs.ciroh.org content | Improves adoption and self-service use | Phase 4 | TBD | proposed |

This table is intended to be a lightweight repository-level summary. If active execution tracking is needed, mirror these items into GitHub Issues or a GitHub Project and keep this document focused on roadmap-level status.

## Prioritization guidance

Prioritize roadmap items in this order:

1. **Interfaces and integration first**  
   Start with metadata, run-directory alignment, and handoff between preprocess, datastream, and execution.

2. **Operations and governance second**  
   Reuse existing CIROH request, support, and release patterns before adding new process layers.

3. **Advanced extensibility and polish third**  
   Leave broader expansion and richer user-facing features until the core ecosystem contracts are stable.

## Recommended maintenance pattern

Use this roadmap as a lightweight planning artifact:

- update phases when milestones change
- assign owners as responsibilities become clear
- use the canonical status values `proposed`, `planned`, `in_progress`, `blocked`, and `complete`
- keep repository links aligned with the current CIROH-UA ecosystem
