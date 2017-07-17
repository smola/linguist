#!/usr/bin/env ruby

require 'github_api'
require 'base64'

samples_dir = 'test_samples'
if not Dir::exists? samples_dir
  Dir::mkdir(samples_dir)
end

token = ENV['GITHUB_TOKEN']
gh = Github.new oauth_token: token

language_queries = {
    'C' => ['language:C include'],
    'C++' => ['language:C++ include'],
    'Puppet' => ['language:Puppet extension:pp class', 'language:Pascal extension:pp include'],
    'Pascal' => ['language:Pascal extension:pp begin']
}

repo_blacklist = %w[
    sillsdevarchive/wsiwaf
    stijn-volckaert/ReMon-clang
]

language_queries.each { |lang, queries|
  puts "Language: #{lang}"
  samples_lang_dir = File.join(samples_dir, lang)
  if not Dir::exists? samples_lang_dir
    Dir::mkdir(samples_lang_dir)
  end
  queries.each { |query|
    puts "\tQuery: #{query}"
    res = gh.search.code q: query
    res.items.each { |item|
      name = item.name
      user = item.repository.owner.login
      repo = item.repository.name
      next if repo_blacklist.include? "#{user}/#{repo}"
      sha = item.sha
      sample_file = File.join(samples_lang_dir, "#{user}+#{repo}+#{sha}+#{name}")
      next if File::exists? sample_file
      blob = gh.git_data.blobs.get(user: user, repo: repo, sha: sha)
      content = Base64.decode64(blob.content)
      puts "\t\tSample: #{sample_file}"
      File.open(sample_file, 'w') { |f| f.write(content) }
    }
  }
}
