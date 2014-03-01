##
## Utilities for working with matrices
##
## Yarden Katz <yarden@mit.edu>
##
import numpy as np
cimport numpy as np

from libc.math cimport log
from libc.math cimport exp

cimport lapack

ctypedef np.int_t DTYPE_t
ctypedef np.float_t DTYPE_float_t


##
## Vector utilities
##
cdef np.ndarray[double, ndim=1] \
  vect_prod(np.ndarray[double, ndim=1] my_vect,
            int vect_len):
    """
    Return vector product.
    """
    cdef int i = 0
    cdef double prod_result = 1.0
    for i in xrange(my_vect):
        prod_result = prod_result * my_vect[i]
    return prod_result

def my_vect_prod(np.ndarray[double, ndim=1] my_vect,
                 int vect_len):
    return vect_prod(my_vect, vect_len)


cdef DTYPE_float_t \
  sum_array(np.ndarray[DTYPE_float_t, ndim=1] input_array,
            DTYPE_t array_len):
    cdef DTYPE_t j = 0
    cdef DTYPE_float_t result = 0.0
    for j in xrange(array_len):
        result += input_array[j]
    return result


cdef np.ndarray[double, ndim=1] \
  log_vect(np.ndarray[double, ndim=1] my_vect,
           int vect_len):
    """
    Return log of vector
    """
    cdef int i = 0
    cdef np.ndarray[double, ndim=1] log_my_vect = \
      np.empty(vect_len, dtype=float)
    for i in xrange(vect_len):
        log_my_vect[i] = log(my_vect[i])
    return log_my_vect


cdef DTYPE_t array_len(np.ndarray[double, ndim=1] my_array):
    """
    Return length of 1d array.
    """
    return my_array.shape[0]

##
## Matrix multiplication from C++
##
#cdef extern from "matrix.h" namespace "matrix":
#   void matrix_mult(double *A, int m, int n, int p, double *B, double *C)
#   void test_mat(double *A, int m, int n)


##
## Matrix addition
##
cdef np.ndarray[double, ndim=2] \
  mat_plus_mat(np.ndarray[double, ndim=2] A,
               int m,
               int n,
               np.ndarray[double, ndim=2] B,
               int p,
               int q):
    """
    Add two matrices together. Adds matrix A (m x n)
    with matrix B (p x q).
    """
    cdef np.ndarray[double, ndim=2] added_mat = \
      np.empty((m, n), dtype=float)
    cdef int i = 0
    cdef int j = 0
    for i in xrange(m):
        for j in xrange(n):
            added_mat[i][j] = A[i][j] + B[i][j]
    return added_mat

def py_mat_plus_mat(np.ndarray[double, ndim=2] A,
                    int m,
                    int n,
                    np.ndarray[double, ndim=2] B,
                    int p,
                    int q):
    """
    Python interface to mat_plus_mat.
    """
    return mat_plus_mat(A, m, n, B, p, q)

##
## Matrix multiplication
##
#@cython.boundscheck(False)
#@cython.wraparound(False)
cdef np.ndarray[double, ndim=2] \
  mat_times_mat(np.ndarray[double, ndim=2] A,
                int m,
                int n,
                int p,
                np.ndarray[double, ndim=2] B):
    """
    Matrix x matrix multiplication.

    A : (m x n) matriax
    B : (n x p) matrix

    return C, an (n x p) matrix.
    """
    cdef int i = 0
    cdef int j = 0
    cdef int k = 0
    # Result matrix
    cdef np.ndarray[double, ndim=2] C = \
      np.zeros((m, p), dtype=float)
    for i in xrange(m):
        for j in xrange(n):
            for k in xrange(p):
                C[i, k] += A[i, j] * B[j, k]
    return C

def py_mat_times_mat(np.ndarray[double, ndim=2] A,
                     int m,
                     int n,
                     int p,
                     np.ndarray[double, ndim=2] B):
    """
    Python interface to mat_times_mat.
    """
    return mat_times_mat(A, m, n, p, B)

##
## Matrix dot product (for 2d arrays, this is equivalent to
## matrix multiplication.)
##
cdef np.ndarray[double, ndim=2] \
  mat_dotprod(np.ndarray[double, ndim=2] A,
              int m,
              int n,
              int p,
              np.ndarray[double, ndim=2] B):
    """
    Dot product of matrix A x matrix B.
    """
    return mat_times_mat(A, m, n, p, B)

##
## Matrix times column vector
##
# ...


##
## Matrix transpose
##
cdef np.ndarray[double, ndim=2] \
  mat_trans(np.ndarray[double, ndim=2] A,
            int m,
            int n):
    """
    Matrix transpose.
 
    A : (m x n) matrix

    Returns A'.
    """
    cdef int i = 0
    cdef int j = 0
    cdef np.ndarray[double, ndim=2] A_trans = np.empty((n, m), dtype=float)
    # By row
    for i in xrange(m):
        # By column
        for j in xrange(n):
            A_trans[j, i] = A[i, j]
    return A_trans

def py_mat_trans(np.ndarray[double, ndim=2] A,
                 int m,
                 int n):
    """
    Python interface to mat_trans.
    """
    return mat_trans(A, m, n)


      