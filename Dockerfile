# List to Pathways (L2P) Single Comparison - Galaxy Tool Container
# Use rocker/tidyverse which has pre-compiled packages for multiple architectures

FROM rocker/tidyverse:4.1.3

LABEL org.opencontainers.image.source="https://github.com/NIDAP-Community/l2p-galaxy-tool"
LABEL org.opencontainers.image.description="List to Pathways (L2P) enrichment analysis tool for Galaxy"
LABEL org.opencontainers.image.licenses="MIT"

# Set environment
ENV LANG=en_US.UTF-8

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install R packages - tidyverse already included in base, just need RCurl
RUN R -q -e "options(repos = c(CRAN = 'https://cran.r-project.org')); install.packages('RCurl')"

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
