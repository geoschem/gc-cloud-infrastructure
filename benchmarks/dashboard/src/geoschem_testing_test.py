#
# Run `python -m pytest` to run these tests.
#

import json
from .geoschem_testing import *


def test_encoding_decoding_dynamodb_dict():
    test_dict_decoded = {
        "string1": "foobar",
        "map1": { "string2": "foo", "bool1": False },
        "list1": ["string3", "string4"],
    }

    test_dict_encoded = {
        "string1": {"S": "foobar"},
        "map1": {
            "M": {
                "string2": {"S": "foo"},
                "bool1": {"BOOL": False}
            },
        },
        "list1": {
            "L": [
                {"S": "string3"},
                {"S": "string4"}
            ]
        }
    }

    decoding_answer = dynamodb_decode_dict(test_dict_encoded)
    assert decoding_answer == test_dict_decoded

    encoding_answer = dynamodb_encode_dict(test_dict_decoded)
    assert encoding_answer == test_dict_encoded


def test_primary_key_classification():
    assert PrimaryKeyClassification(primary_key="gchp-1Mon-13.4.0-rc.3.bd").classification == "GEOS-Chem Simulation"
    assert PrimaryKeyClassification(primary_key="gchp-1Mon-13.4.0-rc.3").classification == "GEOS-Chem Simulation"
    assert PrimaryKeyClassification(primary_key="gchp-c24-1Mon-13.4.0-rc.3").classification == "GEOS-Chem Simulation"
    assert PrimaryKeyClassification(primary_key="gcc-1Hr-483b659.bd").classification == "GEOS-Chem Simulation"
    assert PrimaryKeyClassification(primary_key="gcc-1Hr-483b659").classification == "GEOS-Chem Simulation"
    assert PrimaryKeyClassification(primary_key="gcc-4x5-1Hr-483b659").classification == "GEOS-Chem Simulation"
    assert PrimaryKeyClassification(primary_key="diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27").classification == "Difference Plots"


def test_parsing_scan():
    with open("test_data/scan_results.json") as f:
        response = json.load(f)['Items']
    entries = parse_scan_response(response)

    an_entry_that_should_exist = RegistryEntry(
        primary_key="gcc-1Hr-f9a901a.bd", creation_date="2022-03-24", execution_status="FAILED",
        execution_site="AWS", description="1Hr gcc benchmark simulation using 'f9a901a'",
        s3_uri="s3://benchmarks-cloud/benchmarks/1Hr/gcc/gcc-1Hr-f9a901a.bd",

    )
    assert any([entry == an_entry_that_should_exist for entry in entries])


def test_parsing_query():
    with open("test_data/query_result.json") as f:
        response = [json.load(f)['Item']]
    entries = parse_query_response_astype(response, RegistryEntrySimulation)

    an_entry_that_should_exist = RegistryEntrySimulation(
        primary_key="gchp-1Mon-13.4.0-rc.3.bd", creation_date="2022-03-28", execution_status="SUCCESSFUL",
        execution_site="AWS", description="1Mon gchp benchmark simulation using '13.4.0-rc.3'",
        s3_uri="s3://benchmarks-cloud/benchmarks/1Mon/gchp/gchp-1Mon-13.4.0-rc.3.bd",
    )
    an_entry_that_should_exist.setup_run_directory = RegistryEntryStage(
        name="SetupRunDirectory", completed=True, log_file="http://s3.amazonaws.com/benchmarks-cloud/benchmarks/1Mon/gchp/gchp-1Mon-13.4.0-rc.3.bd/SetupRunDirectory.txt",
        start_time="2022-03-28T17:45:04+0000", end_time="2022-03-28T18:00:15+0000", metadata="{}",
        artifacts=["s3://benchmarks-cloud/benchmarks/1Mon/gchp/gchp-1Mon-13.4.0-rc.3.bd/SetupRunDirectory_RunDirectory.tar.gz"],
        public_artifacts=[],
    )
    an_entry_that_should_exist.run_simulation_directory = RegistryEntryStage(
        name="RunGCHP", completed=True,
        log_file="http://s3.amazonaws.com/benchmarks-cloud/benchmarks/1Mon/gchp/gchp-1Mon-13.4.0-rc.3.bd/RunGCHP.txt",
        start_time="2022-03-28T19:26:04+0000", end_time="2022-03-29T01:45:15+0000", metadata="{}",
        artifacts=[
            "s3://benchmarks-cloud/benchmarks/1Mon/gchp/gchp-1Mon-13.4.0-rc.3.bd/RunGCHP_OutputDir.tar.gz"],
        public_artifacts=[],
    )
    assert entries[0] == an_entry_that_should_exist


def test_parsing_diff_query():
    with open("test_data/diff_query_result.json") as f:
        response = [json.load(f)['Item']]
    entries = parse_query_response_astype(response, RegistryEntryDiff)

    an_entry_that_should_exist = RegistryEntryDiff(
        primary_key="diff-gcc-1Hr-3f70328.bd-gcc-1Hr-3f70328.bd", creation_date="2022-04-04", execution_status="SUCCESSFUL",
        execution_site="AWS", description="1Hr Benchmark plot creation (ref: 'gcc-1Hr-3f70328.bd'; dev:'gcc-1Hr-3f70328.bd')",
        s3_uri="s3://benchmarks-cloud/diff-plots/1Hr/diff-gcc-1Hr-3f70328.bd-gcc-1Hr-3f70328.bd",
    )
    an_entry_that_should_exist.run_gcpy_stage = RegistryEntryStage(
        name="CreateBenchmarkPlots", completed=True, log_file="http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Hr/diff-gcc-1Hr-3f70328.bd-gcc-1Hr-3f70328.bd/CreateBenchmarkPlots.txt",
        start_time="2022-04-04T17:22:44+0000", end_time="2022-04-04T17:23:32+0000", metadata="{}",
        artifacts=[],
        public_artifacts=[
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Hr/diff-gcc-1Hr-3f70328.bd-gcc-1Hr-3f70328.bd/BenchmarkResults/Tables/Emission_totals.txt",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Hr/diff-gcc-1Hr-3f70328.bd-gcc-1Hr-3f70328.bd/BenchmarkResults/Tables/GlobalMass_Trop.txt",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Hr/diff-gcc-1Hr-3f70328.bd-gcc-1Hr-3f70328.bd/BenchmarkResults/Tables/GlobalMass_TropStrat.txt",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Hr/diff-gcc-1Hr-3f70328.bd-gcc-1Hr-3f70328.bd/BenchmarkResults/Tables/Inventory_totals.txt",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Hr/diff-gcc-1Hr-3f70328.bd-gcc-1Hr-3f70328.bd/BenchmarkResults/Tables/OH_metrics.txt",
        ],
    )

    assert entries[0] == an_entry_that_should_exist

def test_parsing_diff_of_diffs_query():
    with open("test_data/diff_of_diffs_query_result.json") as f:
        response = [json.load(f)['Item']]
    entries = parse_query_response_astype(response, RegistryEntryDiff)

    an_entry_that_should_exist = RegistryEntryDiff(
        primary_key="diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27", creation_date="2022-04-13",
        execution_status="SUCCESSFUL",
        execution_site="AWS",
        description="1Mon Benchmark plot diff of diffs (ref: 'gchp-c24-1Mon-13.4.0-alpha.26'; dev: 'gchp-c24-1Mon-13.4.0-alpha.27'; dev: 'gcc-c24-1Mon-13.4.0-alpha.27'; ref: 'gcc-c24-1Mon-13.4.0-alpha.26)",
        s3_uri="s3://benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27",
    )
    an_entry_that_should_exist.run_gcpy_stage = RegistryEntryStage(
        name="CreateBenchmarkPlots", completed=True,
        log_file="http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/CreateBenchmarkPlots.txt",
        start_time="2022-04-13T20:44:26+0000", end_time="2022-04-13T20:53:47+0000", metadata="{}",
        artifacts=[],
        public_artifacts=[
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/lumped_species.yml",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/benchmark_categories.yml",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Aerosols/Aerosols_Surface.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Aerosols/Aerosols_500hPa.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Aerosols/Aerosols_FullColumn_ZonalMean.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Aerosols/Aerosols_Strat_ZonalMean.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Bromine/Bromine_Surface.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Bromine/Bromine_500hPa.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Bromine/Bromine_FullColumn_ZonalMean.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Bromine/Bromine_Strat_ZonalMean.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Chlorine/Chlorine_Surface.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Chlorine/Chlorine_500hPa.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Chlorine/Chlorine_FullColumn_ZonalMean.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Chlorine/Chlorine_Strat_ZonalMean.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Iodine/Iodine_Surface.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Iodine/Iodine_500hPa.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Iodine/Iodine_FullColumn_ZonalMean.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Iodine/Iodine_Strat_ZonalMean.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Nitrogen/Nitrogen_Surface.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Nitrogen/Nitrogen_500hPa.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Nitrogen/Nitrogen_FullColumn_ZonalMean.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Nitrogen/Nitrogen_Strat_ZonalMean.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Oxidants/Oxidants_Surface.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Oxidants/Oxidants_500hPa.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Oxidants/Oxidants_FullColumn_ZonalMean.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Oxidants/Oxidants_Strat_ZonalMean.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Primary_Organics/Primary_Organics_Surface.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Primary_Organics/Primary_Organics_500hPa.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Primary_Organics/Primary_Organics_FullColumn_ZonalMean.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Primary_Organics/Primary_Organics_Strat_ZonalMean.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/ROy/ROy_Surface.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/ROy/ROy_500hPa.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/ROy/ROy_FullColumn_ZonalMean.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/ROy/ROy_Strat_ZonalMean.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Secondary_Organic_Aerosols/Secondary_Organic_Aerosols_Surface.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Secondary_Organic_Aerosols/Secondary_Organic_Aerosols_500hPa.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Secondary_Organic_Aerosols/Secondary_Organic_Aerosols_FullColumn_ZonalMean.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Secondary_Organic_Aerosols/Secondary_Organic_Aerosols_Strat_ZonalMean.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Secondary_Organics/Secondary_Organics_Surface.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Secondary_Organics/Secondary_Organics_500hPa.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Secondary_Organics/Secondary_Organics_FullColumn_ZonalMean.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Secondary_Organics/Secondary_Organics_Strat_ZonalMean.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Sulfur/Sulfur_Surface.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Sulfur/Sulfur_500hPa.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Sulfur/Sulfur_FullColumn_ZonalMean.pdf",
            "http://s3.amazonaws.com/benchmarks-cloud/diff-plots/1Mon/diff-of-diffs-1Mon-gchp-c24-gcc-c24-13.4.0-alpha.26-13.4.0-alpha.27/BenchmarkResults/GCHP_GCC_diff_of_diffs/Sulfur/Sulfur_Strat_ZonalMean.pdf",
        ],
    )

    assert entries[0] == an_entry_that_should_exist


def test_diff_plot_get_put_item():
    new_request = NewDifferencePlot("1234-1Hr-1234", "abcd-1Hr-abcd", "AWS")
    answer = {
        "InstanceID": {"S": "diff-1234-1Hr-1234-abcd-1Hr-abcd"},
        "CreationDate": {"S": date.today().isoformat()},
        "ExecStatus": {"S": "PENDING"},
        "S3Uri": {"S": "s3://benchmarks-cloud/diff-plots/1Hr/diff-1234-1Hr-1234-abcd-1Hr-abcd"},
        "Description": {"S": "Benchmark plots for Ref=1234-1Hr-1234 and Dev=abcd-1Hr-abcd (1Hr)"},
        "Site": {"S": "AWS"},
        "Stages": {"L": []}
    }
    assert new_request.get_put_item() == answer
