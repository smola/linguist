#!/usr/bin/env ruby

require 'github_api'
require 'base64'

samples_dir = 'more_samples'
if not Dir::exists? samples_dir
  Dir::mkdir(samples_dir)
end

token = ENV['GITHUB_TOKEN']
gh = Github.new oauth_token: token

language_queries = {
    'C' => ['extension:c language:C include']
}

language_queries.each { |lang, queries|
  samples_lang_dir = File.join(samples_dir, lang)
  if not Dir::exists? samples_lang_dir
    Dir::mkdir(samples_lang_dir)
  end
  queries.each { |query|
    res = gh.search.code q: query
    res.items.each { |item|
      name = item.name
      user = item.repository.owner.login
      repo = item.repository.name
      sha = item.sha
      blob = gh.git_data.blobs.get(user: user, repo: repo, sha: sha)
      content = Base64.decode64(blob.content)
      sample_file = File.join(samples_lang_dir, "#{user}+#{repo}+#{sha}+#{name}")
      File.open(sample_file, 'w') { |f| f.write(content) }
    }
  }
}
