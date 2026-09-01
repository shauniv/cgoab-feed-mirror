# crazyguyonabike feed mirror

Why this exists: crazyguyonabike.com's `robots.txt` now disallows automated
fetching of `/doc/rss/` (and most of the rest of the site) for everyone
except a few named search-engine bots. Tools like dlvr.it and IFTTT honor
that and refuse to poll the feed directly, even though the feed itself
loads fine in an ordinary browser.

This repo's GitHub Action fetches the real feed on a schedule using normal
browser-style headers (not identifying as an automation bot) and republishes
it as `feed.xml` in this repo. Point your auto-poster (dlvr.it, IFTTT, etc.)
at the mirrored URL below instead of the original.

## One-time setup

1. Create a **public** GitHub repo and push these files to it
   (public keeps the raw/Pages URL simple - there's nothing sensitive in a
   public blog's RSS feed).
2. In the repo, go to **Settings -> Pages** and set Source = "Deploy from a
   branch", Branch = `main`, folder = `/ (root)`. Save.
3. Go to the **Actions** tab, open "Mirror CGOAB RSS feed", and click
   **Run workflow** once to do the first fetch immediately (otherwise it
   waits for the next 30-minute schedule tick).
4. After that first run finishes (~10-20 seconds), your mirrored feed is
   live at:

   - GitHub Pages (preferred - correct XML content-type):
     `https://<your-username>.github.io/<repo-name>/feed.xml`
   - Raw fallback (works immediately, no Pages needed, but serves as
     text/plain which a few strict feed readers dislike):
     `https://raw.githubusercontent.com/<your-username>/<repo-name>/main/feed.xml`

5. In dlvr.it (or IFTTT), use that URL as the RSS source instead of
   `https://www.crazyguyonabike.com/doc/rss/?doc_id=27166`.

## If GitHub's own runners are also blocked

The site's block looks like it's based on the crawler identifying itself
as a bot (robots.txt) rather than blocking by IP, since a plain browser
fetch succeeds. If it turns out GitHub's hosted runner IPs get blocked too,
the fix is to run this same `curl` step on a machine you control instead
(a cron job on your own computer, or a
[self-hosted Actions runner](https://docs.github.com/actions/hosting-your-own-runners))
rather than GitHub's shared runners.
