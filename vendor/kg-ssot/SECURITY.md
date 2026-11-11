# Security policy

KG-SSOT is maintained by one person, in the open, at [github.com/marciocar/kg-ssot](https://github.com/marciocar/kg-ssot).
This page says which versions get security fixes, how to report a vulnerability privately, how fast you get an
answer, what is in scope, and how disclosure is coordinated.

## Supported versions

Only the **latest release** gets security fixes. A fix ships as a new release (a patch or minor version, tagged
`kg-ssot-vX.Y.Z`) on every channel at once: PyPI and npm (`kg-ssot`), the MCP Bundle and the SBOMs attached to the
GitHub release, and the OCI image `ghcr.io/marciocar/kg-ssot`. Earlier versions do not get backports; upgrade to the
latest release. The current version is the `version` field of `spec/release.json` and the newest tag in
[Releases](https://github.com/marciocar/kg-ssot/releases).

| Version | Security fixes |
| --- | --- |
| Latest release | Yes |
| Any earlier release | No: upgrade to the latest |

## Reporting a vulnerability

Report it privately through **GitHub Private Vulnerability Reporting**:
[github.com/marciocar/kg-ssot/security/advisories/new](https://github.com/marciocar/kg-ssot/security/advisories/new)
(the **Security** tab of the repository, then **Report a vulnerability**). The report stays private between you and
the maintainer until the advisory is published.

Please do **not** open a public issue, a pull request, or a discussion for a vulnerability, and do not send it by any
other channel. There is no security e-mail address: the private report is the only channel.

A useful report says:

- the affected package, version and command (for example the `kg-mcp` command of `kg-ssot` 4.49.0 from PyPI, or the
  image digest);
- what an attacker can do, and under which configuration (stdio, HTTP on loopback, the "behind a proxy" profile);
- the steps to reproduce, ideally with a minimal `.kg.yaml` or request;
- whether you plan to publish, and when.

## Response times

These are targets for a one-person project, measured in calendar days from the report:

- **Acknowledgement:** within 7 days.
- **First assessment** (accepted or declined, with a severity estimate): within 14 days.
- **Fix:** for an accepted report, a release with the fix within 90 days, sooner for a severe issue. If a fix takes
  longer, you will hear why and the new date before the 90 days end.

You will get updates in the private advisory as the work moves.

## Scope

In scope: what the release ships and how it is built.

- The tools in the release: the reference reader (`kg_validate.py`), the suite, the gate, the vendor tool, the store,
  query, diff, trace, refs and the other `kg_*.py` modules, and the MCP server (`kg_mcp.py`, also `kg-ssot` and
  `kg-mcp`), in stdio and in HTTP.
- The packages and artifacts: `kg-ssot` on PyPI and on npm, the MCP Bundle (`.mcpb`), and the image
  `ghcr.io/marciocar/kg-ssot`.
- The contract and the conformance suite, when a flaw lets a graph pass that the contract says must fail, in a way
  that matters for security (for example, a path in a graph that makes the store write outside its root).
- The release pipeline: the workflow that publishes the release, its provenance attestations, and its SBOMs.

Out of scope:

- A vulnerability in a third-party dependency (PyYAML, jsonschema, ajv, yaml, the base image). Report it upstream.
  Do tell us if KG-SSOT uses the dependency in a way that makes it exploitable, or if the SBOM of a release lists an
  affected version.
- A deployment that goes against the manual, such as the HTTP server exposed to the internet without the shared
  secret, without TLS, or with the "behind a proxy" profile on a network that clients other than the proxy can reach.
- The content of graphs that adopters write, and secrets that someone commits into a graph.
- Reports from automated scanners with no demonstrated impact, social engineering, and denial of service that needs
  more resources than the attacker already controls.

## Coordinated disclosure

- The default embargo is **90 days** from the report, or the release of the fix, whichever comes first. We can agree
  on a different date in the advisory, for example when a fix needs a change in an upstream project.
- When the fix is released, the maintainer publishes the GitHub Security Advisory, with a CVE requested through
  GitHub when the issue warrants one, and the release notes point to it.
- You are credited in the advisory, unless you ask not to be.
- If the issue is being exploited in the wild, or becomes public before the fix, the maintainer may publish earlier,
  and will tell you first.
- Good-faith research that follows this policy, stays within your own installations and data, and does not harm
  other users is welcome, and the maintainer will not pursue it.

## Verifying a release

Every artifact of a release carries a provenance attestation from GitHub, and an SBOM in CycloneDX JSON:

```sh
gh attestation verify kg-ssot-<version>.mcpb --repo marciocar/kg-ssot
gh attestation verify oci://ghcr.io/marciocar/kg-ssot:<version> --repo marciocar/kg-ssot
```

A release from 4.47.0 on also attests the manifest of its source tree (`<tag>.vendor-manifest.json`), so an adopter
who vendors by tag can check what it brought with `kg_vendor.py update --verify-attestation`.

The SBOM of each artifact (`<artifact>.cdx.json`) is attached to the GitHub release and attested with the
CycloneDX predicate, so `gh attestation verify <artifact> --repo marciocar/kg-ssot --predicate-type
https://cyclonedx.org/bom` checks it. The image SBOM is also attested in the registry, next to the image.
