#!/usr/bin/env bash
# Print one X (Twitter) post as compact text, plus the quoted original when the
# post is a quote-repost. Replies and thread siblings are deliberately not fetched.
#
# Data comes from FxEmbed (api.fxtwitter.com), falling back to the independently
# operated api.vxtwitter.com so one provider outage does not break the fetch.
#
# curl instead of ax: ax caps response bodies and reports `body_truncated`, which
# leaves these payloads unparseable as JSON.

set -euo pipefail

die() { printf 'fetch-x-post: %s\n' "$1" >&2; exit 1; }

[ $# -eq 1 ] || die "usage: fetch-x-post.sh <post URL | post id>"

if [[ $1 =~ ^[0-9]+$ ]]; then
  id=$1
elif [[ $1 =~ /status(es)?/([0-9]+) ]]; then
  id=${BASH_REMATCH[2]}
else
  die "no numeric post id found in: $1"
fi

# Both providers are normalised to one shape so a single renderer serves both.
# shellcheck disable=SC2016  # $p and $x below are jq variables; the shell must not expand them.
RENDER='
def render($p):
  [ "\($p)@\(.handle) (\(.name)) · \(.date)"
  , "\($p)\(.url)"
  , (.reply_to | select(. != null) | "\($p)in reply to @\(.)")
  , ""
  , (.text | select(. != "") | split("\n") | map($p + .) | join("\n"))
  , ( .media[]?
    | "\($p)[\(.type)] \(.url)" + (if (.alt // "") != "" then " (alt: \(.alt))" else "" end) )
  , (.poll[]? | "\($p)[poll] \(.label) — \(.percent)%")
  , (.note | select((. // "") != "") | "\($p)[community note] \(.)")
  , "\($p)\(.metrics)"
  , ( .quote | select(. != null)
    | "\($p)↳ quoting the original post:\n" + render($p + "  ") )
  ] | join("\n");
'

FX="$RENDER"'
def norm:
  { url: .url
  , handle: .author.screen_name
  , name: .author.name
  , date: .created_at
  , text: (.text // "")
  , reply_to: .replying_to
  , media: ( [ (.media.all // [])[] | {type: .type, url: .url, alt: .altText} ]
      + (if .media.external then [{type: "external", url: .media.external.url, alt: null}] else [] end) )
  , poll: (if .poll then [ .poll.choices[] | {label: .label, percent: .percentage} ] else null end)
  , note: (.community_note | if type == "object" then .text else . end)
  , metrics: ( "likes \(.likes // 0) · reposts \(.retweets // 0) · replies \(.replies // 0) · quotes \(.quotes // 0)"
      + (if .views then " · views \(.views)" else "" end) )
  , quote: (if .quote then (.quote | norm) else null end)
  };
.tweet | norm | render("")
'

VX="$RENDER"'
def norm:
  { url: .tweetURL
  , handle: .user_screen_name
  , name: .user_name
  , date: .date
  , text: (.text // "")
  , reply_to: .replyingTo
  , media: [ (.media_extended // [])[] | {type: .type, url: .url, alt: .altText} ]
  , poll: (if .pollData then [ .pollData.options[] | {label: .name, percent: .percent} ] else null end)
  , note: .communityNote
  , metrics: "likes \(.likes // 0) · reposts \(.retweets // 0) · replies \(.replies // 0)"
  , quote: (if .qrt then (.qrt | norm) else null end)
  };
norm | render("")
'

# A bad id can come back as HTTP 200 text/html from FxEmbed, so a cheap probe for
# the id field -- not the status code -- decides whether a provider really answered.
# Rendering errors are left unsuppressed; they are bugs, not a reason to stay quiet.
fetch() {
  local body
  body=$(curl -sS -f --max-time 20 -H 'Accept: application/json' "$1" 2>/dev/null) || return 1
  printf '%s\n' "$body" | jq -e "$3" >/dev/null 2>&1 || return 1
  printf '%s\n' "$body" | jq -r "$2"
}

fetch "https://api.fxtwitter.com/i/status/$id" "$FX" '.tweet.id' \
  || fetch "https://api.vxtwitter.com/i/status/$id" "$VX" '.tweetID' \
  || die "post $id unavailable — deleted, private, or both providers are down"
