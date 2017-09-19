# <`lm`> if a supernatural chicken was haunting you, would that be a poultrygeist?
# <dru> `lm`: I feel like I could set up a pun generator to find words that are a maximum levenshtein distance away
#       from a compound word stem (e.g. poultry --> [polter]geist)
# <dru> I have no idea how to set up the rest of the joke other than manually though
# <dru> "what do you call a [adjective related to poltergeist] [synonym for chicken | chicken] that [verb related
#       to poltergeist]?"
# <dru> thanks for the inspiration bbl

# Intended joke outcome:
#   Q. What do you call a supernatural chicken haunting you?
#   A. A poultrygeist!

# Process:
# 1. Generate core pun word: "chicken"                            # core_word:         "chicken"
# 2. Look up all synonyms/typeOfs for core word                   # synonyms:          ["fowl", "poultry"]
# 3. Find another noun a low L-distance away from one             # related_word:      "poultergeist"
#   - This will probably be the bulk of process time
# 4. Look up adjective that can describe related_word             # related_adjective: "supernatural"
#   - This step can be ommitted without ruining the joke.
# 5. Look up a verb that is often used to describe related_word   # related_verb:      "haunt"
# 6. Choose a random joke template using these tokens             # template:          "Q. What do you call a _ _ _ you? / A. A _!"
#   - This will probably be moved to a higher step once multiple templates require different tokens.
# 7. Prepare the punchline / generate our pun!
# 8. Token replacement for the best joke in the world

require 'unirest'
require 'levenshtein-ffi' # using a native C binding here so comparisons are faster
require 'pry'

MASHAPE_API_KEY = ENV['MASHAPE_API_KEY']
ALLOW_API_CALLS = true

class Log
  CHANNELS_ENABLED = {
    flow:  true,
    info:  true,
    debug: false,
    error: true,
    reasoning: true,
    sequence: false,
  }

  CHANNELS_ENABLED.keys.each do |channel|
    define_singleton_method(channel) do |message|
      puts "[#{channel.upcase}] #{message}" if CHANNELS_ENABLED[channel]
    end
  end
end

class Dictionary
  # TODO: almost all of this -- probably want to use a data structure that makes sorting by Levenshtein distance easier
  attr_accessor :words

  def initialize(filepath)
    # TODO: do some preprocessing here to be able to sort/filter by Levenshtein distance from arbitrary words
    self.words = File.readlines(filepath)
  end

  def random_noun
    # TODO: this is hilariously inefficient
    File.readlines('lists/english-nouns.txt').sample.chomp
  end
end

class Word
  attr_accessor :word, :data

  def initialize(word)
    self.word = word

    populate_data if ALLOW_API_CALLS
  end

  def common_adjectives
    response = Unirest.get(
      "https://api.datamuse.com/words?rel_jjb=#{self.word}",
      headers: { "Accept" => "application/json" }
    ).body

    # TODO: need a new datasource with more adjectives -- this one doesn't have ANY FOR POULTERGEIST!
    response = mock_poultergeist_response if self.word == 'poultergeist'

    # Pull out just the words; we don't care about frequency scores
    response.map { |word_object| word_object['word'] }
  end

  def common_verbs
    # TODO: all of this -- probably need to build out some custom endpoints on Retort to fetch data for:
    #   "give me all verbs we've seen a given noun doing".
    ['haunt', 'spook', 'chill', 'follow']
  end

  private

  def populate_data
    Log.info("Making API request for #{self.word} word data")
    self.data = fetch_word_data
    Log.debug("Response: #{self.data}")

    mock_api_response if self.data == "Too many requests. Please try again."
  end


  def fetch_word_data
    res = Unirest.get "https://wordsapiv1.p.mashape.com/words/#{self.word}",
      headers: {
        "X-Mashape-Key" => MASHAPE_API_KEY,
        "Accept"        => "application/json"
      }

    res.body
  end

  def mock_api_response
    Log.debug "API is overloaded; falling back on mocks for #{self.word}."
    case self.word
      when 'chicken'; self.data = mock_chicken_response
      else;           Log.debug "No mock defined for #{self.word}."
    end
  end

  def mock_chicken_response
    {
      "word": "chicken",
      "results": [
        {
          "definition": "a domestic fowl bred for flesh or eggs; believed to have been developed from the red jungle fowl",
          "partOfSpeech": "noun",
          "synonyms": [
            "gallus gallus"
          ],
          "typeOf": [
            "fowl",
            "poultry",
            "domestic fowl"
          ],
          "hasTypes": [
            "hen",
            "capon",
            "chick",
            "dominick",
            "biddy",
            "spring chicken",
            "cock",
            "rhode island red",
            "rooster",
            "dominique",
            "orpington"
          ],
          "hasParts": [
            "poulet",
            "volaille"
          ]
        },
        {
          "definition": "easily frightened",
          "partOfSpeech": "adjective",
          "synonyms": [
            "chickenhearted",
            "lily-livered",
            "white-livered",
            "yellow",
            "yellow-bellied"
          ],
          "usageOf": [
            "colloquialism"
          ],
          "similarTo": [
            "fearful",
            "cowardly"
          ]
        },
        {
          "definition": "a person who lacks confidence, is irresolute and wishy-washy",
          "partOfSpeech": "noun",
          "synonyms": [
            "crybaby",
            "wimp"
          ],
          "typeOf": [
            "doormat",
            "weakling",
            "wuss"
          ]
        },
        {
          "definition": "the flesh of a chicken used for food",
          "partOfSpeech": "noun",
          "synonyms": [
            "poulet",
            "volaille"
          ],
          "typeOf": [
            "poultry"
          ],
          "hasTypes": [
            "pullet",
            "fryer",
            "roaster",
            "frier",
            "spatchcock",
            "hen",
            "capon",
            "broiler"
          ],
          "hasParts": [
            "chicken wing",
            "white meat",
            "breast"
          ],
          "partOf": [
            "gallus gallus"
          ]
        },
        {
          "definition": "a foolhardy competition; a dangerous activity that is continued until one competitor becomes afraid and stops",
          "partOfSpeech": "noun",
          "typeOf": [
            "contest",
            "competition"
          ]
        }
      ],
      "syllables": {
        "count": 2,
        "list": [
          "chick",
          "en"
        ]
      },
      "pronunciation": {
        "all": "'ʧɪkən"
      },
      "frequency": 4.8
    }
  end

  def mock_poultergeist_response
    [
      { 'word' => 'friendly',     'score' => 1.0 },
      { 'word' => 'spooky',       'score' => 0.8 },
      { 'word' => 'supernatural', 'score' => 0.5 },
      { 'word' => 'blazing',      'score' => 420 }
    ]
  end
end

class Verb < Word
  attr_accessor :word

  def initialize(word)
    self.word = word
  end

  def present_participle_form
    self.word + 'ing' #lol
  end
end

dictionary = Dictionary.new('lists/google-10000-english-no-swears.txt')
Log.debug("Dictionary loaded into memory.")

# 1. Generate core pun word: "chicken"                            # core_word:         "chicken"
core_word = Word.new(dictionary.random_noun)
Log.flow("Chose core word to be #{core_word.word}.")

# 2. Look up all synonyms/typeOfs for core word                   # synonyms:          ["fowl", "poultry"]
synonyms = core_word.data['results']
  .select   { |word| word['partOfSpeech'] == 'noun' }
  .first['typeOf']
  .reject { |word| word.split(' ').count > 1 }
selected_synonym = synonyms.sample
Log.flow("Chose selected_synonym to be #{selected_synonym}.")
Log.debug("From options: #{synonyms}")

if selected_synonym == nil
  Log.error("No synonyms for #{core_word.word} to choose from! Failing gracefully.")
  # TODO: restart the process with a new word in this case
  exit
end

# 3. Find another noun a low L-distance away from one             # related_word:      "poultergeist"
Log.debug("Finding a related word from dictionary.")
related_word_raw_string = dictionary.words
  .reject { |word| word.length < 7 }
  .sort_by do |word|
    word.chomp!

    minimum_distance = selected_synonym.length
    iteratable_chunk_size = [selected_synonym.length, word.length].min

    word.chars.each_cons(iteratable_chunk_size) do |character_sequence|
      next if character_sequence.join == selected_synonym
      levenshtein_distance = Levenshtein.distance(character_sequence.join, selected_synonym)
      Log.sequence "\t#{character_sequence.join} => #{levenshtein_distance} (minimum #{minimum_distance} for #{word})"

      if levenshtein_distance < minimum_distance
        minimum_distance = levenshtein_distance
      end
    end

    minimum_distance
  end
  .first
related_word = Word.new(related_word_raw_string)
Log.flow("Chose related_word to be #{related_word.word}.")

# 4. Look up adjective that can describe related_word             # related_adjective: "supernatural"
related_adjectives = related_word.common_adjectives
related_adjective = related_adjectives.sample
Log.flow("Chose related_adjective to be #{related_adjective}.")
Log.debug("From: #{related_adjectives}")

# 5. Look up a verb that is often used to describe related_word   # related_verb:      "haunt"
related_verbs = related_word.common_verbs
related_verb = Verb.new(related_verbs.sample).present_participle_form
Log.flow("Chose related_verb to be #{related_verb}.")
Log.debug("From: #{related_verbs}")

# 6. Choose a random joke template
joke_templates = [
  # [
  #   "Q. What do you call a <related_adjective> <core_word> <related_verb> you?",
  #   "A. A <pun>!"
  # ].join("\n"),
  [
    "Q. What do you call a <related_adjective> <core_word>?",
    "A. A <pun>!"
  ].join("\n")
]
joke_template = joke_templates.sample
Log.flow("Chose joke template: \n#{joke_template}")

# 7. Prepare the PUNchline                                        # punchline: "poultrygeist"
#  7a. Find the related_word subsequence most similar to our selected_synonym
iteratable_chunk_size    = [selected_synonym.length, related_word.word.length].min
most_similar_subsequence = related_word.word[0, iteratable_chunk_size]
best_subsequence_score   = selected_synonym.length + 1

related_word.word.chars.each_cons(iteratable_chunk_size) do |character_sequence|
  next if character_sequence.join == selected_synonym
  levenshtein_distance = Levenshtein.distance(character_sequence.join, selected_synonym)

  if levenshtein_distance < best_subsequence_score && character_sequence.join != related_word.word
    best_subsequence_score   = levenshtein_distance
    most_similar_subsequence = character_sequence.join
  end
end

if best_subsequence_score > related_word.word.length
  Debug.error("No subsequence to replace. Failing gracefully.")
  exit
end

Log.reasoning("Swapping '#{most_similar_subsequence}' in '#{related_word.word}' with #{selected_synonym} for the punchline.")

#  7b. After finding the sequence to swap our pun into, replace it inline with our selected_synonym
pun = related_word.word.dup
pun[most_similar_subsequence] = selected_synonym

# 8. Token replacement for the best joke in the world
joke = joke_template
  .gsub('<related_adjective>', related_adjective || '')
  .gsub('<core_word>',         core_word.word)
  .gsub('<related_verb>',      related_verb)
  .gsub('<pun>',               pun)

puts "-"*20, joke
