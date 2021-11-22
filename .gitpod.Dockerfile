FROM gitpod/workspace-full

RUN curl -JLO 'https://pm.puppet.com/cgi-bin/pdk_download.cgi?dist=debian&rel=11&arch=amd64&ver=latest' && sudo dpkg -i pdk_2.3.0.0-1bullseye_amd64.deb && rm pdk_2.3.0.0-1bullseye_amd64.deb

