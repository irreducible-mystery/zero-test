#!/usr/bin/env python3
"""The object, defined. Deliberately contains NO analysis -- write your own.

Provided so that two independent workers attack the same object rather than two
different ones. If you think a definition here is wrong, say so; that is a
finding, not a distraction.
"""
from fractions import Fraction

def T(g):
    "[[1,g],[1,0]] as (a,b,c,d)."
    return (1, g, 1, 0)

def mul(A, B):
    a,b,c,d = A; e,f,g,h = B
    return (a*e+b*g, a*f+b*h, c*e+d*g, c*f+d*h)

def word_product(a, w):
    "w is a string of '+'/'-'. Returns the matrix product, left to right."
    P = None
    for ch in w:
        M = T(a if ch == '+' else -a)
        P = M if P is None else mul(P, M)
    return P

def trace_det(A):
    a,b,c,d = A
    return a+d, a*d-b*c

# a exact: pass Fraction. Floating point will not settle a tie.
if __name__ == "__main__":
    a = Fraction(1,10)
    for w in ["+", "-", "+-", "++-", "+-+--"]:
        print(w, trace_det(word_product(a, w)))
