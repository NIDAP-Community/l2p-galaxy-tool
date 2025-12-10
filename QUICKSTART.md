# Quick Start Guide

## Publishing to GitHub

### 1. Create a GitHub Repository

```bash
cd /Users/maggiec/l2p-galaxy-tool

# Initialize git repository
git init
git add .
git commit -m "Initial commit: L2P Galaxy tool with CI/CD"

# Create repository on GitHub (via web interface or gh CLI)
# Then add remote and push:
git branch -M main
git remote add origin https://github.com/NIDAP-Community/l2p-galaxy-tool.git
git push -u origin main
```

### 2. Enable GitHub Container Registry

The workflow is already configured! It will automatically:
- Build the Docker image on push to main
- Publish to `ghcr.io/NIDAP-Community/l2p-galaxy-tool:latest`
- Use `GITHUB_TOKEN` (no additional secrets needed)

### 3. Make the Container Public (Optional)

1. Go to your GitHub profile → Packages
2. Find `l2p-galaxy-tool`
3. Click "Package settings"
4. Scroll to "Danger Zone" → "Change visibility"
5. Select "Public"

### 4. Update the Tool XML

Before pushing, update the container reference in `l2p_single.xml`:

```xml
<container type="docker">ghcr.io/NIDAP-Community/l2p-galaxy-tool:latest</container>
```

Replace `NIDAP-Community` with your actual GitHub username.

### 5. Tag a Release

```bash
git tag v1.1.0
git push origin v1.1.0
```

This creates versioned tags: `v1.1.0`, `v1.1`, `v1`, and `latest`

## Using in Galaxy

### Update Your Galaxy Instance

1. **Update tool XML**:
```bash
# Replace the container reference in your Galaxy tools directory
cd /Users/maggiec/Galaxy/tools/l2p
# Edit l2p_single.xml to use: ghcr.io/NIDAP-Community/l2p-galaxy-tool:latest
```

2. **Restart Galaxy**:
```bash
cd /Users/maggiec/Galaxy
sh run.sh --stop-daemon && sleep 3 && sh run.sh --daemon
```

3. **Test the tool** at http://localhost:8080

### For Public Deployment

If deploying to a shared Galaxy instance:

1. **Pull the image manually** (first time):
```bash
docker pull ghcr.io/NIDAP-Community/l2p-galaxy-tool:latest
```

2. **Configure automatic updates** in Galaxy's job configuration:
```yaml
containers_resolvers:
  - type: explicit
    identifier: ghcr.io/NIDAP-Community/l2p-galaxy-tool:latest
```

## Updating the Tool

### Workflow for Updates

1. Make changes to R scripts or Dockerfile
2. Commit and push to main:
```bash
git add .
git commit -m "Fix: description of changes"
git push origin main
```

3. GitHub Actions automatically builds and publishes new image

4. Create a release tag for major updates:
```bash
git tag v1.2.0
git push origin v1.2.0
```

### Force Galaxy to Pull Latest Image

```bash
# Remove cached image
docker rmi ghcr.io/NIDAP-Community/l2p-galaxy-tool:latest

# Pull fresh image
docker pull ghcr.io/NIDAP-Community/l2p-galaxy-tool:latest

# Restart Galaxy
cd /Users/maggiec/Galaxy
sh run.sh --stop-daemon && sleep 3 && sh run.sh --daemon
```

## Monitoring CI/CD

### Check Build Status

1. Go to your repository on GitHub
2. Click "Actions" tab
3. View workflow runs and logs

### Common Issues

**Build fails:**
- Check GitHub Actions logs
- Verify Dockerfile syntax
- Ensure R packages can be downloaded

**Container not accessible:**
- Make package public (see step 3 above)
- Or configure GitHub token in Galaxy

**Galaxy can't pull image:**
- Check internet connectivity
- Verify image name/tag matches exactly
- Check Docker daemon is running

## Next Steps

- [ ] Replace `NIDAP-Community` with your GitHub username
- [ ] Create GitHub repository
- [ ] Push code and verify CI/CD works
- [ ] Make container package public
- [ ] Update Galaxy tool XML
- [ ] Test in Galaxy
- [ ] Create v1.1.0 release tag
