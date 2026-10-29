# The gate in the adopter's CI

The gate measures every `.kg.yaml` that git tracks in the repository (outside `*/fixtures/*`, `docs/materials/*` and
any folder with the vendor stamp `.kg-ssot-version`) and compares each graph with a recorded baseline. A new graph
cannot enter while it fails MUST, an old graph cannot gain a MUST code, and the SHOULD debt cannot go up.

Set it up from the repository root:

```bash
git add <your .kg.yaml files>      # the gate only measures tracked files
kg-gate --update                   # records the baseline in .kg-ssot/gate/
git add .kg-ssot/gate && git commit -m "record the KG-SSOT gate baseline"
kg-gate                            # rc 0 when nothing got worse
```

Then run it on every pull request. A minimal GitHub Actions workflow, `.github/workflows/kg-ssot.yml`:

```yaml
name: kg-ssot
on: pull_request
jobs:
  gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install kg-ssot==4.39.0
      - run: kg-gate
```

- Pin the version, so the contract only changes when you choose to update it.
- A repository that vendors the kit by tag runs `python3 -I -B vendor/kg-ssot/tools/kg_gate.py` instead, after
  `kg_vendor.py check --dest vendor/kg-ssot`.
- The gate measures only `.kg.yaml`. Validate `.kg.json` files in a step of their own with `kg-validate`.
- When the contract changes on purpose (a new release), run `kg-gate --update` again in the same pull request.
