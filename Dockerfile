
FROM perl:5-slim
LABEL maintainer="Dominique Besagni <dominique.besagni@inist.fr>"

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
    && cpanm -q Encode \
    && cpanm -q URI::Encode \
    && cpanm -q -n -f HTTP::Request HTTP::Response HTTP::Headers HTTP::Status \
    && cpanm -q -n -f HTTP::Cookies HTTP::Negotiate HTTP::Daemon HTML::HeadParser \
    && cpanm -q -n -f Net::SSLeay IO::Socket::SSL \
    && cpanm -q LWP::UserAgent \
    && cpanm -q LWP::Protocol::https \
    && cpanm -q HTTP::CookieJar::LWP \
    && cpanm -q JSON \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && apt-get clean \
    && rm -fr /var/cache/apt/* /var/lib/apt/lists/* \
    && rm -fr ./cpanm /root/.cpanm /usr/src/* /tmp/*


# Run harvestCorpus

WORKDIR /tmp
CMD ["/usr/bin/default.sh"]
