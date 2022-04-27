# Installation

* Install hugo (if you have set up your pi with [pi-tools](https://github.com/scubbo/pi-tools),
  this will already be done):
  * `latestHugoVersion=$(curl -s https://api.github.com/repos/gohugoio/hugo/releases | jq -r '.[] | .tag_name' | perl -pe 's/^v//' | sort -V | tail -n 1)`
  * `wget -q -O /tmp/hugo.deb https://github.com/gohugoio/hugo/releases/download/v${latestHugoVersion}/hugo_${latestHugoVersion}_Linux-ARM.deb`
  * `sudo apt install /tmp/hugo.deb`
* `git submodule init && git submodule update --recursive`

# Use

Content is stored in `blog/`. All `hugo` commands below should be executed from there.
This top-level directory is just for package metadata, `README.md`, etc.

* To create a new post, run `hugo new posts/<name>.md` (or, run `np.sh <name>` _from the root directory_)
* To start a local server to check how it looks, run `hugo server` (with `-D` to show drafts)
