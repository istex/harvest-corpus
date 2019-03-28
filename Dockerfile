
# FROM ubuntu:18.04
FROM perl:5-slim
MAINTAINER Dominique Besagni <dominique.besagni@inist.fr>


# Proxy server settings (if necessary)

ENV http_proxy http://proxyout.inist.fr:8080
ENV https_proxy http://proxyout.inist.fr:8080


# Install applications and set rights

COPY default.sh /usr/bin/default.sh
COPY harvestCorpus.pl /usr/bin/harvestCorpus
COPY outils/extrait-xml-éditeur/extraitXmlEditeur.pl /usr/bin/extraitXmlEditeur
COPY outils/ligature/ligature.pl /usr/bin/ligature
COPY outils/stats-corpus/statsCorpus.pl /usr/bin/statsCorpus

RUN chmod 0755 /usr/bin/default.sh /usr/bin/harvestCorpus /usr/bin/extraitXmlEditeur \
               /usr/bin/ligature /usr/bin/statsCorpus


# Install necessary tools and clean up

# RUN apt-get update \
#    && apt-get install -y apt-utils 

RUN apt-get update \
    && apt-get install -y gcc libc6-dev make openssl libssl-dev zlib1g zlib1g-dev \
    file zip unzip --no-install-recommends \
#     && apt-get install -y cpanminus --no-install-recommends \
#     && rm -rf /var/lib/apt/lists/* \
    && cpanm -q Encode \
    && cpanm -q URI::Encode \
    && cpanm -q -n -f HTTP::Request HTTP::Response HTTP::Headers HTTP::Status \
    && cpanm -q -n -f HTTP::Cookies HTTP::Negotiate HTTP::Daemon HTML::HeadParser \
    && cpanm -q -n -f Net::SSLeay IO::Socket::SSL \
    && cpanm -q LWP::UserAgent \
    && cpanm -q LWP::Protocol::https \
    && cpanm -q HTTP::CookieJar::LWP \
    && cpanm -q JSON \
#     && rm -rf .cpanm \
#     && apt-get purge --auto-remove gcc libc6-dev make openssl libssl-dev zlib1g zlib1g-dev \
#     && apt-get auto-remove --purge gcc libc6-dev make openssl libssl-dev zlib1g zlib1g-dev \
#     && apt-get auto-remove --assume-no gcc libc6-dev make openssl libssl-dev zlib1g zlib1g-dev \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && apt-get clean \
    && rm -fr /var/cache/apt/* /var/lib/apt/lists/* \
    && rm -fr ./cpanm /root/.cpanm /usr/src/* /tmp/*


# Run harvestCorpus

WORKDIR /tmp
CMD ["/usr/bin/default.sh"]
