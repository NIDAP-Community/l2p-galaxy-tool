# L2P Single Comparison - Galaxy Tool Container
# Based on rocker/r-ver with tidyverse dependencies

FROM rocker/r-ver:4.1.3

LABEL org.opencontainers.image.source="https://github.com/NIDAP-Community/l2p-galaxy-tool"
LABEL org.opencontainers.image.description="L2P pathway enrichment analysis tool for Galaxy"
LABEL org.opencontainers.image.licenses="MIT"

# Set environment
ENV LANG=en_US.UTF-8

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    ca-certificates \
    wget \
    build-essential \
    gfortran \
    && rm -rf /var/lib/apt/lists/*

# Install R packages in dependency order with verification
# Install remotes to enable version pinning
RUN R -q -e "options(repos = c(CRAN = 'https://cran.r-project.org'), download.file.method = 'wget', Ncpus = 2, warn = 2); install.packages('remotes', dependencies = TRUE); if (!'remotes' %in% rownames(installed.packages())) q(status = 1)"

# Install curl (pinned to version compatible with system libcurl) and magrittr
RUN R -q -e "options(repos = c(CRAN = 'https://cran.r-project.org'), download.file.method = 'wget', Ncpus = 2, warn = 2); remotes::install_version('curl', version = '4.3.2', dependencies = TRUE, upgrade = 'never'); install.packages('magrittr', dependencies = TRUE); if (!all(c('curl', 'magrittr') %in% rownames(installed.packages()))) q(status = 1)"

# Install RCurl which depends on curl  
RUN R -q -e "options(repos = c(CRAN = 'https://cran.r-project.org'), download.file.method = 'wget', Ncpus = 2, warn = 2); install.packages('RCurl', dependencies = TRUE); if (!'RCurl' %in% rownames(installed.packages())) q(status = 1)"

# Install tidyverse packages
RUN R -q -e "options(repos = c(CRAN = 'https://cran.r-project.org'), download.file.method = 'wget', Ncpus = 2, warn = 2); install.packages(c('dplyr', 'stringr'), dependencies = TRUE); if (!all(c('dplyr', 'stringr') %in% rownames(installed.packages()))) q(status = 1)"

# Install ggplot2
RUN R -q -e "options(repos = c(CRAN = 'https://cran.r-project.org'), download.file.method = 'wget', Ncpus = 2, warn = 2); install.packages('ggplot2', dependencies = TRUE); if (!'ggplot2' %in% rownames(installed.packages())) q(status = 1)"

# Verify all packages installed successfully
RUN R -q -e "required <- c('dplyr', 'magrittr', 'ggplot2', 'stringr', 'RCurl'); installed <- rownames(installed.packages()); missing <- setdiff(required, installed); if (length(missing) > 0) stop('Missing packages: ', paste(missing, collapse = ', ')); cat('All required packages installed successfully:\n'); cat(paste(required, collapse = ', '), '\n')"

# Set working directory
WORKDIR /opt/l2p_single

# Install L2P packages from CCBR
RUN wget -q https://github.com/CCBR/l2p/raw/master/l2p_0.0-13.tar.gz \
  && R CMD INSTALL l2p_0.0-13.tar.gz \
  && rm l2p_0.0-13.tar.gz \
  && wget -q https://github.com/CCBR/l2p/raw/master/l2psupp_0.0-13.tar.gz \
  && R CMD INSTALL l2psupp_0.0-13.tar.gz \
  && rm l2psupp_0.0-13.tar.gz

# Copy L2P scripts
COPY L2P_Single.R /opt/l2p_single/L2P_Single.R
COPY run_L2P_Single.R /opt/l2p_single/run_L2P_Single.R

# Create loader script
RUN echo 'source("/opt/l2p_single/L2P_Single.R")' > /opt/l2p_single/load_L2P_Single.R

CMD ["bash"]
