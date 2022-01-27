## GEOS-Chem Testing Framework

### File Structure
- `helpers/`: Helper scripts (e.g., database helpers and the stage-execution set up script).
- `stages/`: Test stages (e.g., stages for creating the run directory, for running a simulation, for creating benchmark plots). 
- `entrypoints/`: Driver scripts for launching test instances.

### Driver Script Environment Variables 

The following variables control high-level behaviour. Those that aren't marked [optional] must always be set.
  - `GEOSCHEM_BENCHMARK_SCRIPTS`: The full path to '/.../gc-cloud-infrastructure/benchmarks/scripts'.
  - `GEOSCHEM_BENCHMARK_INSTANCE_ID`: The primary key for the test instance (must be unique).
  - `GEOSCHEM_BENCHMARK_INSTANCE_DESCRIPTION`: A description of what the test instance is.
  - `GEOSCHEM_BENCHMARK_S3_BUCKET`: S3 uri of the bucket to which artifacts are uploaded.
  - `GEOSCHEM_BENCHMARK_TABLE_NAME`: DynamoDB table name.
  - `GEOSCHEM_BENCHMARK_SITE`: String specifying which site the test was run at (WUSTL or AWS).
  - `GEOSCHEM_BENCHMARK_TEMPDIR_PREFIX`: [optional] Prefix for temporary directories.
  - `GEOSCHEM_BENCHMARK_WORKING_DIR`: [optional] All stages are run in this directory if it is specified (not recommended, but sometimes useful for testing).


The following variables must be set in any script that uses `setupRunDirectoryGCHP.sh`:
  - `GEOSCHEM_BENCHMARK_COMMIT_ID`: Commit ID to be used.
  - `GEOSCHEM_BENCHMARK_EXTDATA_DIR`: The path to ExtData.
  - `GEOSCHEM_BENCHMARK_START_DATE`: [optional]
  - `GEOSCHEM_BENCHMARK_END_DATE`: [optional]
  - `GEOSCHEM_BENCHMARK_DURATION`: [optional]
  - `GEOSCHEM_BENCHMARK_NUM_PROC`: [optional]
  - `GEOSCHEM_BENCHMARK_NUM_NODES`: [optional]
  - `GEOSCHEM_BENCHMARK_PROC_PER_NODE`: [optional]
  - `GEOSCHEM_BENCHMARK_RESOLUTION`: [optional]

The following variables must be set in any script that uses `createBenchmarkPlots.sh`:
  - `GEOSCHEM_BENCHMARK_REFPK`: InstanceID of ref.
  - `GEOSCHEM_BENCHMARK_DEVPK`: InstanceID of dev.

Not used:
  - `GEOSCHEM_BENCHMARK_CATALOG_FILES`
