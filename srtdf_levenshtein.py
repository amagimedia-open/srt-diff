import os
import sys
import traceback
import numpy as np

#+----------------------------------+
#| Original source : sashis-lv-3.py |
#+----------------------------------+

def _eprint(*args, **kwargs):
    print(*args, file=sys.stderr, flush=True, **kwargs)
    #sys.stderr.flush()

class Levenshtein(object):

    OP_NONE   = '-'
    OP_MATCH  = '='
    OP_SUBST  = 'R'
    OP_DELETE = 'D'
    OP_INSERT = 'I'

    # intmd_state stores the operation 'applied' at [i,j]
    # intmd_state is len(s1)*len(s2) 2-D matrix
    # Each elements of 2-d array can take one of the following values
    #   OP_MATCH  if min(i,j) = min(i-1, j-1)      <- Match
    #   OP_SUBST  if min(i,j) = min(i-1, j-1) + 1  <- Substitution
    #   OP_DELETE if min(i,j) = min(i-1, j) + 1    <- Deletion when transforming s1 to s2
    #   OP_INSERT if min(i,j) = min(i, j-1) + 1    <- Insertion when transforming s1 to s2

    def __init__(self, module_name, from_l, to_l, is_equal_fnx):

        self.m_mn   = module_name
        self.m_from = from_l
        self.m_to   = to_l
        self.m_efnx = is_equal_fnx
        self.m_dist = -1
        self.m_walk_path = []


    def distance(self, verbose):

        if (self.m_dist != -1):
            return self.m_dist  # return result of earlier computation

        #+-----------------------------------------------+
        #| COMPUTE DISTANCE AND FILL INTERMEDIATE STATES |
        #+-----------------------------------------------+

        if (verbose >= 1):
            _eprint("lev:from:len = ", len(self.m_from))
            _eprint("lev:to:len   = ", len(self.m_to))

        if len(self.m_from) == 0:

            intmd_state = [ [OP_INSERT] * (len(self.m_to) + 1) ]
            self.m_intmd_state[0][0] = Levenshtein.OP_NONE
            self.m_dist = len(self.m_to)

        elif len(self.m_to) == 0:

            intmd_state = [ [OP_DELETE] for i in range(len(self.m_from) + 1) ]
            self.m_intmd_state[0][0] = Levenshtein.OP_NONE
            self.m_dist = len(self.m_from)

        else:

            intmd_state = [ [Levenshtein.OP_NONE]*(len(self.m_to) + 1) 
                            for i in range(len(self.m_from) + 1)]
            for i in range(1, len(self.m_from) + 1):
                intmd_state[i][0] = Levenshtein.OP_DELETE
            for j in range(1, len(self.m_to) + 1):
                intmd_state[0][j] = Levenshtein.OP_INSERT
            if (verbose >= 2):
                _eprint(np.matrix(intmd_state))

            previous_row = range(len(self.m_to) + 1)

            for i, c1 in enumerate(self.m_from, 1):     # i starts from 1

                current_row = [i]

                if (verbose >= 1):
                    _eprint("lev:from:current_row = ", i)

                for j, c2 in enumerate(self.m_to, 1):   # j starts from 1,...

                    is_same = (self.m_efnx (c1,c2))

                    deletions     = previous_row[j] + 1 
                    insertions    = current_row [j - 1] + 1       
                    substitutions = previous_row[j - 1] + int(not is_same)
                    min_val       = min(insertions, deletions, substitutions)
                    current_row.append(min_val)

                    if (verbose >= 2):
                        _eprint("")
                        _eprint(np.matrix(previous_row))
                        _eprint(np.matrix(current_row))
                        _eprint("M, @>[", i, j, "], S>(", c1, c2, ")", ", I>", insertions, ", D>", deletions, ", R>", substitutions, ", M>", min_val)

                    if min_val == insertions:
                        intmd_state[i][j] = Levenshtein.OP_INSERT
                    elif min_val == deletions:
                        intmd_state[i][j] = Levenshtein.OP_DELETE
                    elif (min_val == substitutions) and not is_same:
                        intmd_state[i][j] = Levenshtein.OP_SUBST
                    else:
                        intmd_state[i][j] = Levenshtein.OP_MATCH

                    if (verbose >= 2):
                        _eprint(np.matrix(intmd_state))

                previous_row = current_row
            
            self.m_dist = previous_row[-1]

        #+---------------+
        #| SET WALK PATH |
        #+---------------+

        i = len(self.m_from)
        j = len(self.m_to)

        while True:
            op = intmd_state[i][j]
            if (verbose >= 1):
                _eprint("W, @>[", i,j, "], O>", op)
            if op == Levenshtein.OP_DELETE:
                self.m_walk_path.append((op, self.m_from[i-1], None))
                i = i-1
            elif op == Levenshtein.OP_INSERT:
                self.m_walk_path.append((op, None, self.m_to[j-1]))
                j = j-1
            else:
                self.m_walk_path.append((op, self.m_from[i-1], self.m_to[j-1]))
                i = i-1
                j = j-1

            if i==0 and j==0:
                break

        self.m_walk_path.reverse()

        #+-----------------+
        #| RETURN DISTANCE |
        #+-----------------+

        return self.m_dist


    def walk(self):

        for op in self.m_walk_path:
            yield op


def utest_1(verbose):
    print("#---[utest_1]---")

    s1 = "foo world bar"
    s2 = "hello foo boo world"

    print("s1 = ", s1)
    print("s2 = ", s2)

    lev = Levenshtein(g_module_name, 
                      s1.split(), 
                      s2.split(), 
                      lambda s1, s2 : s1 == s2)
    lev_dist = lev.distance(verbose)

    print(lev_dist)
    for op in lev.walk():
        print(op)

def utest_2(verbose):

    print("#---[utest_2]---")

    l1 = [
            (84400,"The"),
            (84599,"Chinese"),
            (84932,"war"),
            (85266,"mantle"),
            (85599,"meaning"),
            (85933,"adviser")
         ]

    l2 = [
            (85000,"Chinese"),
            (85480,"war"),
            (85624,"mental"),
            (85768,"meaning"),
            (85912,"advisor"),
            (85500,"to-the-king")
        ]

    print("l1 = ", l1)
    print("l2 = ", l2)

    lev = Levenshtein(g_module_name, 
                      l1, 
                      l2, 
                      lambda e1, e2 : e1[1] == e2[1])
    lev_dist = lev.distance(verbose)

    print(lev_dist)
    for op in lev.walk():
        print(op)


if __name__ == "__main__":

    g_module_name  = os.path.basename(__file__)

    utest_1(2)
    utest_2(2)


