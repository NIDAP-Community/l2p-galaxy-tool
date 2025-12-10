# L2P Galaxy Tool - Repository Summary

## 📁 Repository Contents

```
l2p-galaxy-tool/
├── .github/
│   └── workflows/
│       └── docker-publish.yml      # CI/CD for Docker builds
├── test_data/
│   └── deg_results.csv            # Sample test data
├── .gitignore                     # Git ignore patterns
├── CHANGELOG.md                   # Version history
├── Dockerfile                     # Container definition
├── L2P_Single.R                   # Core analysis (802 lines, iteration 19)
├── LICENSE                        # MIT License
├── l2p_single.xml                # Galaxy tool wrapper
├── QUICKSTART.md                  # Setup instructions
├── README.md                      # Full documentation
└── run_L2P_Single.R              # CLI wrapper script
```

## 🎯 What's Included

### Core Files
- **L2P_Single.R**: Main analysis functions with all plot fixes (50pt margins, wrapped labels, corrected x-axis)
- **run_L2P_Single.R**: Command-line wrapper that parses arguments and executes analysis
- **l2p_single.xml**: Galaxy tool definition (configure for ghcr.io)

### Docker
- **Dockerfile**: Complete container definition based on rocker/r-ver:4.1.3
- Includes all R dependencies and L2P packages from CCBR

### CI/CD
- **docker-publish.yml**: Automated workflow that:
  - Builds on push to main
  - Publishes to GitHub Container Registry
  - Tags with version numbers, SHA, and 'latest'
  - Uses GitHub Actions cache for faster builds

### Documentation
- **README.md**: Complete user and developer guide
- **QUICKSTART.md**: Step-by-step setup instructions
- **CHANGELOG.md**: Version history and fixes
- **LICENSE**: MIT license

### Test Data
- **deg_results.csv**: Sample differential expression data for testing

## 🚀 Ready to Deploy

### Before You Start

Replace `NIDAP-Community` in these files:
1. `README.md` (multiple locations)
2. `l2p_single.xml` (container reference)
3. `Dockerfile` (LABEL org.opencontainers.image.source)
4. `QUICKSTART.md` (example commands)

### Setup Checklist

- [ ] Create GitHub repository named `l2p-galaxy-tool`
- [ ] Replace `NIDAP-Community` with your GitHub username in files above
- [ ] Update LICENSE copyright with your name/organization
- [ ] Initialize git and push to GitHub
- [ ] Wait for first GitHub Action to complete
- [ ] Make container package public (optional)
- [ ] Test by pulling image: `docker pull ghcr.io/NIDAP-Community/l2p-galaxy-tool:latest`
- [ ] Update your Galaxy tool XML to reference the new container
- [ ] Create v1.1.0 release tag

## 📊 Key Features

### Plot Improvements (Iteration 19)
✅ **Bar plots**: 50pt top margin (lines 237, 266 in L2P_Single.R)
✅ **Bubble plots**: 50pt top margin + wrapped labels + fixed x-axis (line 352)
✅ **All plots**: 10×8 inches @ 150 DPI (1500×1200 pixels)

### Technical Stack
- **Base**: rocker/r-ver:4.1.3
- **R Version**: 4.1.3
- **Key Packages**: ggplot2, dplyr, magrittr, stringr, RCurl
- **L2P**: v0.0-13 (from CCBR)
- **Input Format**: Tab-delimited (Galaxy tabular)
- **Output Formats**: PNG (plots), CSV (pathways)

## 🔄 CI/CD Workflow

### Automatic Triggers
- Push to `main` → builds `latest` tag
- Push tag `v*` → builds versioned tags (e.g., `v1.1.0`, `v1.1`, `v1`)
- Pull request → builds but doesn't publish (for testing)

### Published Tags
Every successful build creates:
- `ghcr.io/NIDAP-Community/l2p-galaxy-tool:latest`
- `ghcr.io/NIDAP-Community/l2p-galaxy-tool:main-<sha>`
- `ghcr.io/NIDAP-Community/l2p-galaxy-tool:v1.1.0` (on version tags)

### Build Cache
GitHub Actions caches Docker layers for faster subsequent builds.

## 🔧 Local Development

### Build Locally
```bash
cd /Users/maggiec/l2p-galaxy-tool
docker build -t l2p-galaxy-tool:dev .
```

### Test Locally
```bash
docker run --rm -v $(pwd)/test_data:/data l2p-galaxy-tool:dev \
  Rscript /opt/l2p_single/run_L2P_Single.R \
  /data/deg_results.csv \
  /data/output.csv \
  /data/bar_up.png \
  /data/bar_down.png \
  /data/bubble_up.png \
  /data/bubble_down.png \
  symbol Human TRUE \
  PSA_high-PSA_low_tstat \
  PSA_high-PSA_low_pval \
  PSA_high-PSA_low_FC \
  0.05 1.2
```

### Update and Test Cycle
1. Edit `L2P_Single.R` or `run_L2P_Single.R`
2. Rebuild: `docker build -t l2p-galaxy-tool:dev .`
3. Test with sample data
4. Commit and push when satisfied
5. CI/CD automatically publishes

## 📝 Next Actions

### Immediate
1. **Update placeholders**: Replace `NIDAP-Community` throughout
2. **Create repository**: Initialize on GitHub
3. **First push**: Trigger initial CI/CD build
4. **Verify build**: Check GitHub Actions completes successfully
5. **Test pull**: Ensure you can pull the published image

### After Publishing
1. **Update Galaxy**: Modify tool XML to use new container reference
2. **Test in Galaxy**: Run with sample data
3. **Create release**: Tag v1.1.0 for official release
4. **Document usage**: Add examples and screenshots
5. **Share**: Announce availability to your team/community

## 🎉 Benefits of This Setup

✅ **Reproducibility**: Container ensures consistent environment
✅ **Version Control**: Git tracks all changes to code
✅ **Automated Building**: CI/CD handles Docker builds
✅ **Easy Updates**: Push changes → automatic rebuild
✅ **Public Access**: Anyone can use `ghcr.io/NIDAP-Community/l2p-galaxy-tool:latest`
✅ **Versioning**: Semantic version tags for stable releases
✅ **Documentation**: Complete guides for users and developers

## 📚 Documentation Structure

- **README.md**: Main documentation (users + developers)
- **QUICKSTART.md**: Fast setup guide (step-by-step)
- **CHANGELOG.md**: Version history (what changed and when)
- **This file**: Repository overview (what's included and why)

## 🤝 Acknowledgments

Based on L2P package from [CCBR/l2p](https://github.com/CCBR/l2p)

Plot improvements developed through 19 iterations to achieve publication-quality output with proper margins, label wrapping, and axis calculations.
