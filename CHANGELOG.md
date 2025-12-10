# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-12-10

### Added
- Initial release with GitHub Container Registry support
- CI/CD pipeline via GitHub Actions
- Automated Docker image building and publishing

### Fixed
- **Plot title cutoff**: Increased top margin from 30pt to 50pt on all plots (bar and bubble)
- **Bubble plot label readability**: Added 30-character label wrapping with size 8 font
- **Bubble plot x-axis**: Fixed narrow x-axis bug by correcting range calculation
- **Bar plot formatting**: Ensured consistent 50pt top margin across both p-value modes

### Changed
- Updated plot dimensions to 10×8 inches @ 150 DPI (1500×1200 pixels)
- Improved bubble plot theme to match bar plot robustness
- Switched from local Docker image to ghcr.io container registry

### Technical Details
- Base image: rocker/r-ver:4.1.3
- R packages: dplyr, magrittr, ggplot2, stringr, RCurl
- L2P packages: l2p_0.0-13, l2psupp_0.0-13 (from CCBR)
- File format: Tab-delimited input (Galaxy tabular format)
- Output formats: PNG (plots), CSV (pathways table)

## [1.0.0] - Previous

### Initial Implementation
- L2P pathway enrichment analysis
- Support for GO, REACTOME, and KEGG databases
- Bar and bubble plot generation
- Separate analysis for up/down regulated genes
- Gene selection by rank or thresholds
