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
    && rm -rf /var/lib/apt/lists/*

# Install R packages in dependency order
# First install base dependencies
RUN R -q -e " \
  options( \
    repos = c(CRAN = 'http://cran.r-project.org'), \
    download.file.method = 'wget' \
  ); \
  install.packages('magrittr', dependencies = TRUE); \
  "

# Install tidyverse core packages
RUN R -q -e " \
  options( \
    repos = c(CRAN = 'http://cran.r-project.org'), \
    download.file.method = 'wget' \
  ); \
  install.packages('dplyr', dependencies = TRUE); \
  "

# Install remaining packages
RUN R -q -e " \
  options( \
    repos = c(CRAN = 'http://cran.r-project.org'), \
    download.file.method = 'wget' \
  ); \
  pkgs <- c('ggplot2', 'stringr', 'RCurl'); \
  install.packages(pkgs, dependencies = TRUE); \
  "

# Verify all packages installed successfully
RUN R -q -e " \
  required <- c('dplyr', 'magrittr', 'ggplot2', 'stringr', 'RCurl'); \
  installed <- rownames(installed.packages()); \
  missing <- setdiff(required, installed); \
  if (length(missing) > 0) stop('Missing packages: ', paste(missing, collapse = ', ')); \
  cat('All required packages installed successfully\n'); \
  "

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
