# Publishing to NIDAP-Community on GitHub

This guide walks through publishing the L2P Galaxy Tool to the NIDAP-Community GitHub organization.

## 🎯 Final Configuration

All files have been updated to reference:
```
ghcr.io/nidap-community/l2p-galaxy-tool:latest
```

## 📋 Pre-Publishing Checklist

### 1. Verify All Files Updated
```bash
cd /Users/maggiec/l2p-galaxy-tool

# Check that NIDAP-Community is referenced correctly
grep -r "NIDAP-Community" .
grep -r "nidap-community" .
```

### 2. Update LICENSE
Edit `LICENSE` to add copyright holder:
```
Copyright (c) 2025 NIDAP Community / NIH
```

### 3. Review Files
- [ ] `Dockerfile` - Contains NIDAP-Community in LABEL
- [ ] `l2p_single.xml` - References ghcr.io/nidap-community/l2p-galaxy-tool:latest
- [ ] `README.md` - All examples use nidap-community
- [ ] `QUICKSTART.md` - Setup instructions updated
- [ ] `LICENSE` - Copyright updated

## 🚀 Publishing Steps

### Step 1: Create Repository on GitHub

Option A: **Using GitHub Web Interface**
1. Go to https://github.com/NIDAP-Community
2. Click "New repository"
3. Repository name: `l2p-galaxy-tool`
4. Description: `L2P pathway enrichment analysis tool for Galaxy with automated Docker builds`
5. Public repository
6. **Do NOT initialize** with README, .gitignore, or license (we have these)
7. Click "Create repository"

Option B: **Using GitHub CLI** (if you have `gh` installed)
```bash
cd /Users/maggiec/l2p-galaxy-tool
gh repo create NIDAP-Community/l2p-galaxy-tool \
  --public \
  --description "L2P pathway enrichment analysis tool for Galaxy" \
  --source=. \
  --remote=origin
```

### Step 2: Configure Git and Push

```bash
cd /Users/maggiec/l2p-galaxy-tool

# Configure git (if not already done)
git config user.name "Your Name"
git config user.email "your.email@nih.gov"

# Add all files (already staged)
git add .

# Initial commit
git commit -m "Initial release: L2P Galaxy tool v1.1.0

- L2P pathway enrichment analysis for Galaxy
- Automated CI/CD via GitHub Actions
- Published to GitHub Container Registry
- Fixed plot formatting (50pt margins, wrapped labels, corrected x-axis)
- Based on CCBR/l2p with publication-quality plot improvements"

# Add remote (replace with actual repo URL if using web interface)
git remote add origin https://github.com/NIDAP-Community/l2p-galaxy-tool.git

# Push to GitHub
git push -u origin main
```

### Step 3: Wait for First Build

1. Go to https://github.com/NIDAP-Community/l2p-galaxy-tool/actions
2. Watch the "Build and Push Docker Image" workflow
3. Wait ~5-10 minutes for build to complete
4. Verify success (green checkmark)

### Step 4: Make Container Package Public

After first successful build:

1. Go to https://github.com/orgs/NIDAP-Community/packages
2. Find `l2p-galaxy-tool`
3. Click on the package
4. Click "Package settings" (right sidebar)
5. Scroll to "Danger Zone" → "Change package visibility"
6. Select "Public"
7. Type the repository name to confirm
8. Click "I understand, change package visibility"

### Step 5: Create Release Tag

```bash
cd /Users/maggiec/l2p-galaxy-tool

# Create and push v1.1.0 tag
git tag -a v1.1.0 -m "Release v1.1.0: Initial public release with plot fixes"
git push origin v1.1.0
```

This triggers another build with version tags: `v1.1.0`, `v1.1`, `v1`, and `latest`

### Step 6: Verify Container is Accessible

```bash
# Pull the published image
docker pull ghcr.io/nidap-community/l2p-galaxy-tool:latest

# Test it works
docker run --rm ghcr.io/nidap-community/l2p-galaxy-tool:latest R --version
```

## 🔧 Update Your Galaxy Instance

### Option 1: Update Existing Tool (Recommended)

```bash
cd /Users/maggiec/Galaxy/tools/l2p

# Backup current XML
cp l2p_single.xml l2p_single.xml.backup

# Update the container reference
cat > l2p_single.xml << 'EOF'
<tool id="l2p_single" name="L2P Single Comparison" version="1.1.0">
    <description>L2P pathway over-representation with plots</description>

    <requirements>
        <container type="docker">ghcr.io/nidap-community/l2p-galaxy-tool:latest</container>
    </requirements>

    <!-- rest of XML remains the same -->
EOF
```

Or simply edit the container line in your existing XML:
```xml
<container type="docker">ghcr.io/nidap-community/l2p-galaxy-tool:latest</container>
```

### Option 2: Copy New Tool File

```bash
# Copy the updated XML from the repository
cp /Users/maggiec/l2p-galaxy-tool/l2p_single.xml /Users/maggiec/Galaxy/tools/l2p/l2p_single.xml
```

### Restart Galaxy

```bash
cd /Users/maggiec/Galaxy
sh run.sh --stop-daemon && sleep 3 && sh run.sh --daemon
```

## 📊 Testing

### Test Container Pull
```bash
docker pull ghcr.io/nidap-community/l2p-galaxy-tool:latest
```

### Test in Galaxy
1. Go to http://localhost:8080
2. Find "L2P Single Comparison" tool
3. Upload test data: `/Users/maggiec/l2p-galaxy-tool/test_data/deg_results.csv`
4. Configure parameters:
   - Gene name column: `symbol`
   - Species: `Human`
   - Select by rank: `Yes`
   - Ranking column: `PSA_high-PSA_low_tstat`
   - Significance column: `PSA_high-PSA_low_pval`
   - Fold-change column: `PSA_high-PSA_low_FC`
5. Execute and verify outputs

## 🎨 GitHub Repository Polish

### Add Repository Topics

On GitHub repository page:
1. Click ⚙️ next to "About"
2. Add topics:
   - `galaxy`
   - `bioinformatics`
   - `pathway-analysis`
   - `enrichment-analysis`
   - `docker`
   - `github-actions`
   - `nidap`
   - `r-package`

### Add README Badge

Add this badge to the top of README.md:
```markdown
[![Docker Build](https://github.com/NIDAP-Community/l2p-galaxy-tool/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/NIDAP-Community/l2p-galaxy-tool/actions/workflows/docker-publish.yml)
```

### Create GitHub Release

1. Go to https://github.com/NIDAP-Community/l2p-galaxy-tool/releases
2. Click "Create a new release"
3. Choose tag: `v1.1.0`
4. Release title: `v1.1.0 - Initial Public Release`
5. Description:
```markdown
## L2P Galaxy Tool v1.1.0

Initial public release of the L2P pathway enrichment analysis tool for Galaxy.

### Features
- L2P pathway over-representation analysis
- Support for GO, REACTOME, and KEGG databases
- Bar and bubble plot visualizations
- Separate analysis for up/down regulated genes
- Flexible gene selection (by rank or thresholds)

### Plot Improvements
- Fixed title cutoff with 50pt top margins
- Added pathway label wrapping (30 characters)
- Corrected x-axis range calculations in bubble plots
- Optimized dimensions (10×8 inches @ 150 DPI)

### Container
Published to GitHub Container Registry:
`ghcr.io/nidap-community/l2p-galaxy-tool:latest`

### Credits
Based on the L2P package from [CCBR/l2p](https://github.com/CCBR/l2p)
```
6. Click "Publish release"

## 📝 Post-Publication Tasks

### Update Documentation
- [ ] Add link to GitHub repository in NIDAP documentation
- [ ] Create usage examples with screenshots
- [ ] Document common troubleshooting steps

### Announce
- [ ] Share with NIDAP community
- [ ] Post in relevant Slack/Teams channels
- [ ] Update Galaxy tool documentation

### Monitor
- [ ] Watch for GitHub issues
- [ ] Monitor CI/CD build status
- [ ] Track container download statistics

## 🔄 Future Updates

### Making Changes
```bash
cd /Users/maggiec/l2p-galaxy-tool

# Make your changes to L2P_Single.R or other files
# Test locally if needed

git add .
git commit -m "Fix: description of changes"
git push origin main

# GitHub Actions automatically builds and publishes new image
```

### Creating New Releases
```bash
# Update CHANGELOG.md with changes
git add CHANGELOG.md
git commit -m "Update changelog for v1.2.0"
git push origin main

# Create new version tag
git tag -a v1.2.0 -m "Release v1.2.0: Description"
git push origin v1.2.0
```

## 🆘 Troubleshooting

### Build Fails
- Check https://github.com/NIDAP-Community/l2p-galaxy-tool/actions
- Review error logs
- Common issues:
  - Network problems downloading R packages
  - Dockerfile syntax errors
  - Base image unavailable

### Container Not Accessible
- Verify package is public
- Check exact image name/tag
- Try: `docker pull ghcr.io/nidap-community/l2p-galaxy-tool:latest`

### Galaxy Can't Find Container
- Ensure Galaxy has internet access
- Check Docker daemon is running
- Verify container name in XML matches exactly
- Restart Galaxy after XML changes

## ✅ Success Criteria

- [ ] Repository created at https://github.com/NIDAP-Community/l2p-galaxy-tool
- [ ] First CI/CD build completed successfully
- [ ] Container published to ghcr.io/nidap-community/l2p-galaxy-tool:latest
- [ ] Container is publicly accessible
- [ ] v1.1.0 release created
- [ ] Galaxy tool updated and tested
- [ ] Documentation complete and accurate

## 📞 Support

For questions or issues:
- Open an issue: https://github.com/NIDAP-Community/l2p-galaxy-tool/issues
- Contact NIDAP team
- Check Galaxy logs: `/Users/maggiec/Galaxy/database/gravity/log/gunicorn.log`

## 🎉 Congratulations!

Your L2P Galaxy tool is now:
✅ Published on GitHub
✅ Automatically built via CI/CD
✅ Available on GitHub Container Registry
✅ Ready for community use
✅ Properly versioned and documented
