from spacy.lang.en import English
nlp = English()
# Create a Tokenizer with the default settings for English
# including punctuation rules and exceptions
tokenizer = nlp.Defaults.create_tokenizer(nlp)

phrase = "I've finished my work, I'd move on to something else."

tokens = tokenizer(phrase)

for t in tokens:
    if not t.is_punct:
        print(t)
