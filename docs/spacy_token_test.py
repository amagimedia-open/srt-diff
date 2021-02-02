#from spacy.lang.en import English
#import spacy.lang.en
#nlp = spacy.lang.en.English()

#at command line
#python3 -m spacy download en

import spacy

#+-------+
#| INPUT |
#+-------+

phrase = "i've finished my work, I'd move on to something else."

print ("#PHRASE")
print(f"{phrase}")

#+--------------+
#| TOKENIZATION |
#+--------------+

nlp = spacy.load("en")
# Create a Tokenizer with the default settings for English
# including punctuation rules and exceptions
tokenizer = nlp.Defaults.create_tokenizer(nlp)
tokens = tokenizer(phrase)

print ("#TOKENIZATION")
count = 1
token_list = []
for t in tokens:
    if (not t.is_punct):
        print(f"{count},{t}")
        token_list.append(t.text)
        count = count + 1

phrase2 = " ".join(token_list)

#+----------------+
#| CLASSIFICATION |
#+----------------+

nlp = spacy.load("en_core_web_sm")
doc = nlp(phrase2)

print ("")
print ("#CLASSIFICATION")
count = 1
for token in doc:
    print(f"{count},{token.text},{token.pos_},{token.tag_},{token.dep_},{token.is_stop}")
    count = count + 1

