FROM ruby:alpine

RUN set -ex; \
    apk add --no-cache --virtual build_deps \ 
        build-base \
        libc-dev \
        linux-headers \
        cmake \
        icu-dev \
        libressl-dev; \
    apk --no-cache add icu-libs libressl3.1-libssl; \
    gem install github-linguist; \
# remove linguist grammars, not needed in the CLI
    rm -rf /usr/local/bundle/gems/github-linguist-*/grammars/*; \
# remove cruft
    rm -rf /usr/local/bundle/gems/rugged-*/vendor/libgit2; \
    rm -rf /usr/local/bundle/gems/*/ext; \
    rm -rf /usr/local/bundle/cache; \
    find /usr/local/bundle/gems/ -name '*.so' -delete; \
# strip debug symbols
    find /usr/local/bundle -name '*.so' -exec strip --strip-all '{}' +; \
# remove build dependencies
    apk del build_deps; \
# smoke test
    github-linguist /bin/sh

CMD ["github-linguist"]
