require_relative "./helper"

class TestClassifier < Minitest::Test
  include Linguist

  def fixture(name)
    File.read(File.join(samples_path, name))
  end

  def test_classify
    db = {}
    Classifier.train! db, "Ruby", fixture("Ruby/foo.rb")
    Classifier.train! db, "Objective-C", fixture("Objective-C/Foo.h")
    Classifier.train! db, "Objective-C", fixture("Objective-C/Foo.m")

    results = Classifier.classify(db, fixture("Objective-C/hello.m"))
    assert_equal "Objective-C", results.first[0]

    tokens  = Tokenizer.tokenize(fixture("Objective-C/hello.m"))
    results = Classifier.classify(db, tokens)
    assert_equal "Objective-C", results.first[0]
  end

  def test_restricted_classify
    db = {}
    Classifier.train! db, "Ruby", fixture("Ruby/foo.rb")
    Classifier.train! db, "Objective-C", fixture("Objective-C/Foo.h")
    Classifier.train! db, "Objective-C", fixture("Objective-C/Foo.m")

    results = Classifier.classify(db, fixture("Objective-C/hello.m"), ["Objective-C"])
    assert_equal "Objective-C", results.first[0]

    results = Classifier.classify(db, fixture("Objective-C/hello.m"), ["Ruby"])
    assert_equal "Ruby", results.first[0]
  end

  def test_instance_classify_empty
    results = Classifier.classify(Samples.cache, "")
    assert results.first[1] < 0.5, results.first.inspect
  end

  def test_instance_classify_nil
    assert_equal [], Classifier.classify(Samples.cache, nil)
  end

  def test_classify_xvalidation
    return
    samples = []
    data = {}
    samples_per_lang = {}
    Samples.each do |sample|
      language = sample[:language]
      samples_per_lang[language] ||= []
      samples_per_lang[language].push(sample)
      samples.push(sample)
      path = sample[:path]
      data[path] = File.read(sample[:path])
    end

    samples.each do |sample|
      path = sample[:path]
      language  = Linguist::Language.find_by_name(sample[:language])
      if samples_per_lang[sample[:language]].length <= 1
        STDERR.puts "Skip #{path} (only 1 sample)"
        next
      end

      languages = Language.find_by_filename(sample[:path]).map(&:name)
      next unless languages.length != 1

      languages = Language.find_by_extension(sample[:path]).map(&:name)
      next unless languages.length > 1

      STDERR.puts "Testing #{path}"
      db = {}
      samples.each do |training_sample|
        if sample[:path] == training_sample[:path]
          next
        end
        Classifier.train!(db, training_sample[:language], data[training_sample[:path]])
      end

      classifier = Classifier.new(db)
      results = classifier.classify(data[path], languages)
      if language.name != results.first[0]
        STDERR.puts "Need more samples for #{language.name}, failed with #{path} #{results.inspect}"
      end
      #assert_equal language.name, results.first[0], "#{sample[:path]}\n#{results.inspect}"
    end
  end

  def test_classify_test_samples
    test_dir = 'test_samples'
    Dir.foreach(test_dir) { |lang|
      next if lang.start_with? '.'
      expected_language  = Linguist::Language.find_by_name(lang)
      lang_dir = File.join(test_dir, lang)
      Dir.foreach(lang_dir) { |file|
        next if file.start_with? '.'
        file_path = File.join(lang_dir, file)
        #candidates = Language.find_by_extension(file)
        candidates = Linguist::Language.all
        results = Classifier.call(FileBlob.new(file_path), candidates)
        if expected_language != results.first
          STDERR.puts "Need more samples for #{expected_language}, failed with #{file_path} #{results.first}"
        end
        #assert_equal language.name, results.first[0], "#{sample[:path]}\n#{results.inspect}"
      }
    }
  end

  def test_classify_empty_languages
    assert_equal [], Classifier.classify(Samples.cache, fixture("Ruby/foo.rb"), [])
  end
end
