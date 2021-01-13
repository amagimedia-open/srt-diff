import spacy

nlp = spacy.load("en_core_web_sm")
doc = nlp("Okay. What have we got here? The name is an ancient Chinese war mantle meaning 'adviser to the king'. South American insurgency tactics. Talks like a Baptist preacher. There's lots of pageantry going on here. Lots of theater. Close. The heat from the blast was in excess of 3,000 degrees Celsius. Any subjects within 12.5 yards were vaporised instantly")

for token in doc:
        print(token.text, token.pos_, token.tag_, token.dep_,
                            token.is_stop)
