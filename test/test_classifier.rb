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

  def test_classify_ambiguous_languages
    data_by_sample = Hash.new
    tokens_by_sample = Hash.new
    Samples.each do |sample|
      path = sample[:path]
      data = File.read(path)
      tokens = Tokenizer.tokenize(data)
      data_by_sample[path] = data
      tokens_by_sample[path] = tokens
    end

    Samples.each do |sample|
      #puts "Testing #{sample[:path]}"
      language  = Linguist::Language.find_by_name(sample[:language])
      languages = Language.find_by_filename(sample[:path]).map(&:name)
      next if languages.length == 1

      languages = Language.find_by_extension(sample[:path]).map(&:name)
      next if languages.length <= 1

      db = {}
      Samples.each do |training_sample|
        next if training_sample[:path] == sample[:path]
        Classifier.train! db, training_sample[:language], tokens_by_sample[training_sample[:path]]
      end

      notEnough = false
      languages.each do |lang|
        if !db['languages'].has_key?(lang)
          puts "need at least one more sample for #{lang}"
          notEnough = true
        end
      end
      if notEnough
        next
      end

      results = Classifier.classify(db, data_by_sample[sample[:path]], languages)
      if language.name != results.first[0]
        puts "MISCLASSIFICATION: #{language.name} != #{results.first[0]} | #{sample[:path]}\n#{results.inspect}"
      end
    end
  end

  def test_classify_empty_languages
    assert_equal [], Classifier.classify(Samples.cache, fixture("Ruby/foo.rb"), [])
  end
end
