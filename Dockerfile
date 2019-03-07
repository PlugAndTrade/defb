FROM elixir:1.7-alpine

RUN apk add --no-cache git build-base

RUN mkdir -p /app/defb
WORKDIR /app/defb

ADD mix.exs /app/defb
ADD mix.lock /app/defb
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix deps.compile

ADD . /app/defb/

ARG MIX_ENV=prod

RUN mix compile --env=prod && \
    mix release --env=prod

FROM alpine

RUN apk add --no-cache bash ncurses-libs tzdata openssl

WORKDIR /defb
RUN mkdir -p /etc/defb

COPY --from=0 /app/defb/_build/prod/rel/defb/releases/latest/defb.tar.gz /tmp/
COPY --from=0 /app/defb/pages /etc/defb/pages

RUN tar xvzf /tmp/defb.tar.gz && rm -f /tmp/defb.tar.gz

ENV REPLACE_OS_VARS true

CMD [ "/defb/bin/defb", "foreground" ]
