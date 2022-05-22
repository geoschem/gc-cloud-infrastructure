import dataclasses
import re


@dataclasses.dataclass
class PrimaryKeyClassification:
    classification: str = None
    api: str = None
    primary_key: dataclasses.InitVar[str] = None
    code_url: str = None
    commit_id: str = None
    time_period: str = None

    def __post_init__(self, primary_key):
        semver_re = r"(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?"
        commit_hash_re = r"[0-9a-f]{7}"
        simulation_re = rf"(gcc|gchp)-((2x25|2x2\.5|4x5|c?24|c?48|c?90|c?180)-)?(1Mon-|1Hr-)?({semver_re}|{commit_hash_re})(\.bd)?"
        diff_of_diffs_re = rf"diff-of-diffs-1Mon-(gcc|gchp)-(2x25|2x2\.5|4x5|c?24|c?48|c?90|c?180)-(gcc|gchp)-(2x25|2x2\.5|4x5|c?24|c?48|c?90|c?180)-({semver_re}|{commit_hash_re})-({semver_re}|{commit_hash_re})"
        if "1Mon" in primary_key:
            self.time_period = "1Mon"
        elif "1Hr" in primary_key:
            self.time_period = "1Hr"
        else:
            self.time_period = "Unknown"

        if re.match(rf"^{simulation_re}$", primary_key):
            if re.match(r"^gchp", primary_key):
                self.classification = "GEOS-Chem Simulation"
                repo = "GCHP"
            else:
                self.classification = "GEOS-Chem Simulation"
                repo = "GCClassic"
            semver_tag = re.search(semver_re, primary_key)
            if semver_tag:
                self.commit_id = semver_tag.group(0)
                self.commit_id = self.commit_id.removesuffix(".bd")  # for old entries
                self.code_url = (
                    f"https://github.com/geoschem/{repo}/tree/{self.commit_id}"
                )
            commit_hash = re.search(commit_hash_re, primary_key)
            if commit_hash:
                self.commit_id = commit_hash.group(0)
                self.commit_id = self.commit_id.removesuffix(".bd")  # for old entries
                self.code_url = (
                    f"https://github.com/geoschem/{repo}/commit/{self.commit_id}"
                )
            self.api = "simulation"
        elif re.match(rf"^diff-{simulation_re}-{simulation_re}$", primary_key):
            self.classification = "Difference Plots"
            self.api = "difference"
        elif re.match(diff_of_diffs_re, primary_key):
            self.classification = "Difference Plots"
            self.api = "difference"
        else:
            self.classification = "Unknown"
            self.api = None
