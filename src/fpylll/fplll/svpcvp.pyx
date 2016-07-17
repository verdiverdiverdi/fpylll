# -*- coding: utf-8 -*-
include "fpylll/config.pxi"
include "cysignals/signals.pxi"

"""
Shortest and Closest Vectors.

.. moduleauthor:: Martin R. Albrecht <martinralbrecht+fpylll@googlemail.com>
"""

import threading

from libcpp.vector cimport vector
from fpylll.gmp.mpz cimport mpz_t
from fplll cimport Z_NR
from fplll cimport SVP_DEFAULT, CVP_DEFAULT
from fplll cimport SVP_VERBOSE, CVP_VERBOSE
from fplll cimport SVP_OVERRIDE_BND
from fplll cimport SVPM_PROVED, SVPM_FAST
from fplll cimport SVPMethod
from fplll cimport shortest_vector_pruning
from fplll cimport shortest_vector as shortest_vector_c
from fplll cimport vector_matrix_product
from lll import lll_reduction
from fpylll.io cimport assign_Z_NR_mpz, mpz_get_python
from fpylll.util import ReductionError

from integer_matrix cimport IntegerMatrix

def shortest_vector(IntegerMatrix B, method=None, int flags=SVP_DEFAULT, pruning=None, run_lll=True):
    """Return a shortest vector.

    :param IntegerMatrix B:
    :param method:
    :param int flags:
    :param pruning:
    :returns:
    :rtype:

    """
    cdef SVPMethod method_
    if method == "proved" or method is None:
        method_ = SVPM_PROVED
    elif method == "fast":
        method_ = SVPM_FAST
    else:
        raise ValueError("Method '{}' unknown".format(method))

    cdef int r = 0

    if run_lll:
        lll_reduction(B)

    cdef vector[Z_NR[mpz_t]] sol_coord
    cdef vector[Z_NR[mpz_t]] solution
    cdef vector[double] pruning_

    if pruning:
        if len(pruning) != B.nrows:
            raise ValueError("Pruning vector must have length %d but got %d."%(B.nrows, len(pruning)))

        pruning_.resize(B.nrows)
        for i in range(len(pruning)):
            pruning_[i] = pruning[i]

        with nogil:
            sig_on()
            r = shortest_vector_pruning(B._core[0], sol_coord, pruning_, flags)
            sig_off()
    else:
        with nogil:
            sig_on()
            r = shortest_vector_c(B._core[0], sol_coord, method_, flags)
            sig_off()

    if r:
        raise ReductionError("SVP solver returned an error ({:d})".format(r))

    vector_matrix_product(solution, sol_coord, B._core[0])

    cdef list v = []

    for i in range(solution.size()):
        v.append(mpz_get_python(solution[i].get_data()))

    return tuple(v)

class SVP:
    shortest_vector = shortest_vector
    DEFAULT = SVP_DEFAULT
    VERBOSE = SVP_VERBOSE
    OVERRIDE_BND = SVP_OVERRIDE_BND

# class CVP:
#     closest_vector = closest_vector
#     DEFAULT = CVP_DEFAULT
#     VERBOSE = CVP_VERBOSE
