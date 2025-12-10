# L2P Galaxy Tool

A Galaxy tool for performing L2P (Leading edge to Pathway) pathway enrichment analysis on differential expression data. This tool generates both bar plots and bubble plots for upregulated and downregulated gene sets.

## Features

- **Automated pathway enrichment analysis** using GO, REACTOME, and KEGG databases
- **Dual plot types**: Bar plots and bubble plots for visualization
- **Separate analysis** for upregulated and downregulated genes
- **Flexible gene selection**: By rank (e.g., t-statistic) or by thresholds (p-value and fold-change)
- **Publication-ready plots** with proper formatting (50pt top margins, wrapped labels, optimized dimensions)
- **Container-based deployment** via GitHub Container Registry (ghcr.io)

## Container Image

The Docker container is automatically built and published to GitHub Container Registry via CI/CD:

```
ghcr.io/NIDAP-Community/l2p-galaxy-tool:latest
```

### Available Tags

- `latest` - Latest build from the main branch
- `v1.1.0` - Specific version tags
- `main-<sha>` - Commit-specific builds

## Usage in Galaxy

### Installation

1. Add the tool to your Galaxy instance by copying `l2p_single.xml` to your tools directory
2. Update your `tool_conf.xml` to include:

```xml
<section id="ccbr_tools" name="CCBR Tools">
    <tool file="path/to/l2p_single.xml" />
</section>
```

3. Ensure Docker is configured in your Galaxy job configuration:

```yaml
runners:
  local:
    load: galaxy.jobs.runners.local:LocalJobRunner
    workers: 4

execution:
  default: docker_local
  environments:
    docker_local:
      runner: local
      docker_enabled: true
      docker_sudo: false
```

4. Update the container reference in `l2p_single.xml`:

```xml
<container type="docker">ghcr.io/NIDAP-Community/l2p-galaxy-tool:latest</container>
```

### Input Requirements

The tool requires a **tabular** (tab-delimited) differential expression file with:

- **Gene identifier column** (e.g., gene symbols)
- **Ranking column** (e.g., t-statistic) - for rank-based selection
- **Significance column** (e.g., p-value)
- **Fold-change column** (linear scale, not log2)

Example format:
```
symbol	PSA_high-PSA_low_tstat	PSA_high-PSA_low_pval	PSA_high-PSA_low_FC
GENE1	5.2	0.001	2.3
GENE2	-4.1	0.003	0.4
```

### Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| DEG table | Tab-delimited differential expression results | Required |
| Gene name column | Column containing gene identifiers | `symbol` |
| Species | Human or Mouse | Human |
| Select by rank | Use ranking instead of thresholds | Yes |
| Ranking column | Column for ranking genes (e.g., t-stat) | `groupA_vs_groupB_tstat` |
| Significance column | P-value column | `groupA_vs_groupB_pval` |
| Fold-change column | Linear fold-change column | `groupA_vs_groupB_FC` |
| Significance threshold | P-value cutoff | 0.05 |
| Fold-change threshold | Linear FC cutoff | 1.2 |

### Outputs

1. **Pathways CSV** - Enriched pathways for both up and down genes
2. **Bar Plot (Upregulated)** - Bar chart of top enriched pathways (upregulated genes)
3. **Bar Plot (Downregulated)** - Bar chart of top enriched pathways (downregulated genes)
4. **Bubble Plot (Upregulated)** - Bubble plot showing pathway enrichment (upregulated genes)
5. **Bubble Plot (Downregulated)** - Bubble plot showing pathway enrichment (downregulated genes)

All plots are generated as PNG files (1500×1200 pixels, 150 DPI) with optimized formatting:
- 50pt top margin to prevent title cutoff
- Wrapped pathway labels (30 characters max)
- Proper axis scaling and spacing

## Development

### Building Locally

```bash
docker build -t l2p-galaxy-tool .
```

### Testing Locally

```bash
docker run --rm -v $(pwd)/test_data:/data l2p-galaxy-tool \
  Rscript /opt/l2p_single/run_L2P_Single.R \
  /data/deg_results.csv \
  /data/pathways.csv \
  /data/bar_up.png \
  /data/bar_down.png \
  /data/bubble_up.png \
  /data/bubble_down.png \
  symbol \
  Human \
  TRUE \
  PSA_high-PSA_low_tstat \
  PSA_high-PSA_low_pval \
  PSA_high-PSA_low_FC \
  0.05 \
  1.2
```

### Repository Structure

```
l2p-galaxy-tool/
├── .github/
│   └── workflows/
│       └── docker-publish.yml    # CI/CD workflow
├── Dockerfile                     # Container definition
├── L2P_Single.R                   # Core L2P analysis functions
├── run_L2P_Single.R              # Command-line wrapper
├── l2p_single.xml                # Galaxy tool definition
├── LICENSE                        # License file
└── README.md                      # This file
```

## CI/CD Pipeline

The GitHub Actions workflow automatically:

1. **Builds** the Docker image on every push to main
2. **Tags** images appropriately:
   - `latest` for main branch
   - `v*` for version tags
   - `main-<sha>` for commit tracking
3. **Pushes** to GitHub Container Registry
4. **Caches** build layers for faster subsequent builds

### Triggering a Release

Create a version tag:

```bash
git tag v1.1.0
git push origin v1.1.0
```

This will build and publish with tags: `v1.1.0`, `v1.1`, `v1`, and `latest`

## Credits

Based on the L2P package from [CCBR/l2p](https://github.com/CCBR/l2p).

Plot formatting improvements:
- Fixed title cutoff with increased top margins
- Added pathway label wrapping for readability
- Corrected x-axis range calculations
- Optimized plot dimensions for publication quality

## License

MIT License - See LICENSE file for details

## Troubleshooting

### Galaxy Issues

**Container not found:**
- Ensure the container reference in XML matches your published image
- Check Docker is enabled in Galaxy job configuration
- Verify the container is public or GitHub token is configured

**Plots have cut-off titles:**
- Update to the latest container version (includes 50pt top margin fix)
- Check container is pulling the latest image (not cached)

**Worker crashes:**
- Set `preload: false` in `galaxy.yml`
- Disable mulled container resolvers in `container_resolvers.yml`

### Docker Issues

**Build fails:**
- Check Docker has internet access for downloading R packages
- Verify base image `rocker/r-ver:4.1.3` is accessible
- Review GitHub Actions logs for specific errors

## Support

For issues and questions:
- Open an issue on GitHub
- Check existing issues for solutions
- Review Galaxy logs at `database/gravity/log/gunicorn.log`
