import dataclasses
from datetime import date
from ..helpers.dynamodb import dynamodb_encode_dict


@dataclasses.dataclass
class NewDifferencePlot:
    ref: str
    dev: str
    execution_site: str

    def get_put_item(self):
        primary_key = f"diff-{self.ref}-{self.dev}"

        if "-1Hr-" in self.ref:
            s3_uri_suffix = "1Hr"
        elif "-1Day-" in self.ref:
            s3_uri_suffix = "1Day"
        elif r"-1Mon-" in self.ref:
            s3_uri_suffix = "1Mon"
        else:
            raise RuntimeError("No period regex matched reference key")
        if self.execution_site == "AWS":
            s3_uri = "s3://benchmarks-cloud/diff-plots"
        elif self.execution_site == "WUSTL":
            s3_uri = "s3://washu-benchmarks-cloud/diff-plots"
        else:
            raise RuntimeError("Invalid site.")
        s3_uri = f"{s3_uri}/{s3_uri_suffix}/{primary_key}"

        item = {
            "InstanceID": primary_key,
            "CreationDate": date.today().isoformat(),
            "ExecStatus": "PENDING",
            "S3Uri": s3_uri,
            "Description": f"Benchmark plots for Ref={self.ref} and Dev={self.dev} ({s3_uri_suffix})",
            "Site": self.execution_site,
            "Stages": [],
        }
        item = dynamodb_encode_dict(item)
        return item
