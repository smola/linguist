require 'linguist/tokenizer'
require 'set'
#require 'decisiontree'

module Linguist
  class TreeClassifier

    def self.call(blob, possible_languages)

    end

    def classify(blob, possible_languages)
        
    end

    def gen_vocabulary(samples)
        vocab = Vocabulary.new
        puts "Building vocabulary"
        samples.each { |sample|
            data = File.read(sample[:path])
            tokens = Tokenizer.tokenize(data)
            language = sample[:language]
            vocab.add!(tokens, language)
        }
        puts "Pruning vocabulary (size = #{vocab.words.size})"
        vocab.prune!(2)
        vocab.finish!
        puts "Pruned vocabulary (size = #{vocab.words.size})"
        vocab
    end

    def gen_dataset(vocab, samples)
        res = Array.new
        samples.each { |sample|
            path = sample[:path]
            data = File.read(path)
            sample = vocab.to_sample(data, sample[:language])
            sample['extension'] = path.split('.').last
            res << sample
        }
        res
    end

    def train!(samples)
        vocab = gen_vocabulary(samples)
        puts "Building dataset"
        attributes = vocab.words
        training = gen_dataset(vocab, samples)

        #puts "Training"
        #dec_tree = DecisionTree::ID3Tree.new(attributes, training, 'Other', :discrete)
        #dec_tree.train
        #puts "Trained"
    end

  end

  class Vocabulary
    def initialize
        @vocab = {}
        @per_lang = {}
    end

    def add!(data, language)
        if data.is_a?(String)
            tokens = Tokenizer.tokenize(data)
        else
            tokens = data
        end

        @per_lang[language] ||= {}
        tokens.uniq.each { |tok|
            @vocab[tok] ||= 0
            @vocab[tok] += 1
            @per_lang[language][tok] ||= 0
            @per_lang[language][tok] += 1
        }
    end

    def prune!(min_freq)
        valid = Set.new
        @per_lang.each { |lang,toks|
            toks.each { |tok,freq|
                if freq >= min_freq
                    valid << tok
                end
            }
        }
    
        @vocab.delete_if { |tok,freq| !valid.include?(tok) }
    end

    def finish!
        @vocab = @vocab.sort_by { |k,v| v }.to_h
        @per_lang = nil
    end

    def words
        @vocab.keys
    end

    def to_h
        @vocab
    end
 
    def to_sample(data, language)
        if data.is_a?(String)
            tokens = Tokenizer.tokenize(data)
        else
            tokens = data
        end

        sample = {
            'attributes' => {},
            'class' => language
        }

        tokens.uniq.each { |tok|
            if @vocab.key?(tok)
                sample['attributes'][tok] = 1
            end
        }

        return sample
    end
  end
end