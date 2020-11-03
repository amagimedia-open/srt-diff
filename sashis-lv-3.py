import numpy as np

def levenshtein(s1, s2):
    """Implements Levenshtein algorithm as described in
    https://en.wikipedia.org/wiki/Levenshtein_distance

    :param s1: list of string corresponding to first sentence
    :type s1: list
    :param s2: list of string corresponding to second sentence
    :type s2: list
    :return: Levenshtein distance i.e. number of edits required to go from s1 to s2
    :rtype: int
    """
    # len(s1) >= len(s2)
    if len(s2) == 0:
        return len(s1)

    if len(s1) == 0:
        return len(s2)

    # intmd_state is len(s1)*len(s2) 2-D matrix
    # Each elements of 2-d array can take one of the following values
    #   -                                    None
    #   M if min(i,j) = min(i-1, j-1)     <- Match
    #   S if min(i,j) = min(i-1, j-1) + 1 <- Substitution
    #   D if min(i,j) = min(i-1, j) + 1   <- Deletion when transforming s1 to s2
    #   I if min(i,j) = min(i, j-1) + 1   <- Insertion when transforming s1 to s2

    intmd_state = [ ['-']*(len(s2) + 1) for i in range(len(s1) + 1)]

    for i in range(1, len(s1) + 1):
        intmd_state[i][0] = 'D'
    for j in range(1, len(s2) + 1):
        intmd_state[0][j] = 'I'
    
    previous_row = range(len(s2) + 1)
    print(np.matrix(intmd_state))
    for i, c1 in enumerate(s1, 1): # i starts from 1
        current_row = [i]
        for j, c2 in enumerate(s2, 1): # j starts from 1,...
            deletions = previous_row[j] + 1 
            insertions = current_row[j - 1] + 1       
            substitutions = previous_row[j - 1] + (c1 != c2)
            min_val = min(insertions, deletions, substitutions)
            current_row.append(min_val)

            print("")
            print(np.matrix(previous_row))
            print(np.matrix(current_row))
            print("M, @>[", i, j, "], S>(", c1, c2, ")", ", I>", insertions, ", D>", deletions, ", R>", substitutions, ", M>", min_val)
            if min_val == insertions:
                intmd_state[i][j] = 'I'
            elif min_val == deletions:
                intmd_state[i][j] = 'D'
            elif min_val == substitutions and (c1 != c2):
                intmd_state[i][j] = 'R'
            else:
                intmd_state[i][j] = '='

            print(np.matrix(intmd_state))

        previous_row = current_row
    
    print("Levenshtein distance=", previous_row[-1])

    out_sent1 = []
    out_sent2 = []

    i = len(s1)
    j = len(s2)

    while True:
        print("W, @>[", i,j, "], O>", intmd_state[i][j])
        if intmd_state[i][j] == 'D':
            out_sent1.append(s1[i-1])
            out_sent2.append("$$$")
            i = i-1
        elif intmd_state[i][j] == 'I':
            out_sent1.append("$$$")
            out_sent2.append(s2[j-1])
            j = j-1
        else:
            out_sent1.append(s1[i-1])
            out_sent2.append(s2[j-1])
            i = i -1
            j = j-1

        if i==0 and j==0:
            break

    out_sent1.reverse()
    out_sent2.reverse()
    print("out sentence 1: ", out_sent1)
    print("out sentence 2: ", out_sent2)
    return previous_row[-1]


if __name__ == "__main__":
    import sys
    # Example Usage
    if len(sys.argv) < 2:
        print('Usage: python sentence_distance.py "sentence1" "sentence2"')
        print('Example usage')
        print('python sentence_distance.py "foo bar" "foo bar world"')
        print('python sentence_distance.py "hello world" "hello world"')
        print('python sentence_distance.py "Hello foo World my name is abc" "Hello World boo def is my name"')
        sys.exit(1)

    sentence_1 = sys.argv[1].split(" ")
    sentence_2 = sys.argv[2].split(" ")
    print(levenshtein(sentence_1, sentence_2)/max(len(sentence_1),
                                                  len(sentence_2)))

