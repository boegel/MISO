#-*- mode: python-mode -*-
##
## MISO scoring functions in Cython for MCMC sampler
##
### How to pass numpy arrays to C/C++ functions:
### http://stackoverflow.com/questions/3046305/simple-wrapping-of-c-code-with-cython
import numpy as np
cimport numpy as np
np.import_array()

cimport cython
from cython.view cimport array as cvarray
from cpython.array cimport array, clone
cdef double[:] DOUBLE_ARRAY = array("d")
cdef double[:, :] DOUBLE_ARRAY_2D

cimport stat_helpers
cimport matrix_utils

from libc.math cimport log
from libc.math cimport exp
from libc.stdlib cimport rand

ctypedef np.int_t DTYPE_t
ctypedef np.float_t DTYPE_float_t

cdef float MY_MAX_INT = float(10000)
import misopy

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
cdef DTYPE_float_t my_logsumexp(np.ndarray[DTYPE_float_t, ndim=1] log_vector,
                                int vector_len):
    """
    Log sum exp.

    Parameters:
    -----------

    log_vector : array of floats corresponding to log values.
    vector_len : int, length of vector.

    Returns:
    --------

    Result of log(sum(exp(log_vector)))
    """
    cdef DTYPE_float_t curr_exp_value = 0.0
    cdef DTYPE_float_t sum_of_exps = 0.0
    cdef DTYPE_float_t log_sum_of_exps = 0.0
    cdef int curr_elt = 0
    # First find the maximum value first
    cdef DTYPE_float_t max_val = log_vector[0]
    for curr_elt in xrange(vector_len):
        if (log_vector[curr_elt] > max_val):
            max_val = log_vector[curr_elt]
    # Subtract maximum value from the rest
    for curr_elt in xrange(vector_len):
        curr_exp_value = exp(log_vector[curr_elt] - max_val)
        sum_of_exps += curr_exp_value
    # Now take log of the sum of exp values and add
    # back the missing value
    log_sum_of_exps = log(sum_of_exps) + max_val
    return log_sum_of_exps


def py_my_logsumexp(np.ndarray[DTYPE_float_t, ndim=1] log_vector,
                    int vector_len):
    """
    Version of my_logsumexp that is callable from Python.
    """
    return my_logsumexp(log_vector, vector_len)


##
## MCMC proposal functions
## 
# cdef propose_psi_vector(cnp.ndarray[DTYPE_float_t, ndim=1] alpha_vector):
#     """
#     Propose a new Psi vector.  Depends only on the alpha_vector
#     of parameters of the Dirichlet distribution from which the
#     current Psi vector was drawn.
#     """
#     cdef:
#         cnp.ndarray[DTYPE_float_t, ndim=1] proposed_psi_vector
#         cnp.ndarray[DTYPE_float_t, ndim=1] proposed_alpha_vector
#     proposed_psi_vector, proposed_alpha_vector = \
#         propose_norm_drift_psi_alpha(alpha_vector)
#     return (proposed_psi_vector, proposed_alpha_vector)


##
## MCMC sampler logic functions
##
# def compute_metropolis_ratio(self, reads, assignments, proposed_psi_vector,
#                              proposed_alpha_vector,
#                              curr_psi_vector, curr_alpha_vector,
#                              hyperparameters,
#                              full_metropolis):
#     """
#     Compute the Metropolis-Hastings ratio:

#         P(psi_next)Q(psi; psi_next)
#         ---------------------------
#         P(psi)Q(psi_next; psi)

#     Parameters:
#     -----------
#     reads : array, reads to be processed
#     assignments : array, assignments of reads to isoforms
#     proposed_psi_vector : array, proposed Psi vector
#     proposed_alpha_vector : array, proposed alpha vector (parameter to Dirichlet)
#     from which the Psi value vector was drawn
#     curr_psi_vector : array, current Psi vector
#     curr_alpha_vector : array, current alpha vector (parameter to Dirichlet)
#     hyperparameters : array, hyperparameters for scoring
#     full_metropolis : int, if 1 then compute full MH ratio, otherwise not
#     """
#     # Compute acceptance ratio: the joint score for proposed Psi divided
#     # by joint score given current Psi
#     # P(Psi', ...)
#     proposed_joint_score = \
#         self.log_score_joint(reads, assignments, proposed_psi_vector,
#                              gene, hyperparameters)
#     # P(Psi, ...)
#     curr_joint_score = \
#         self.log_score_joint(reads, assignments, curr_psi_vector,
#                              gene, hyperparameters)
#     if curr_joint_score == -inf:
#         self.miso_logger.error("Joint score of current state is negative infinity!")
#         self.miso_logger.error("  - assignments: " + str(assignments))
#         self.miso_logger.error("  - psi vector: " + str(curr_psi_vector))
#         self.miso_logger.error("  - reads: " + str(reads))
#         raise Exception, "curr_joint_score is negative."
#     # Q(x; x'), the probability of proposing to move back to current state from
#     # proposed state x'
#     mh_ratio = None
#     proposal_to_curr_score = \
#         log_score_psi_vector_transition(curr_psi_vector, proposed_alpha_vector)
#     # Q(x'; x), the probability of proposing to move to the proposed state x' from
#     # the current state
#     curr_to_proposal_score = \
#         log_score_psi_vector_transition(proposed_psi_vector, curr_alpha_vector)
#     # Computing full Metropolis-Hastings ratio
#     if full_metropolis == 0:
#         # Not full MH; just ratio of proposed to current joint score
#         mh_ratio = (proposed_joint_score - curr_joint_score)
#     else:
#         # Full MH ratio
#         mh_ratio = (proposed_joint_score + proposal_to_curr_score) - \
#                    (curr_joint_score + curr_to_proposal_score)
#     if curr_to_proposal_score == (-1 * INFINITY):
#         self.miso_logger.error("curr to proposal is -inf")
#         raise Exception, "curr to proposal is -Inf"
#     if proposed_joint_score == (-1 * INFINITY):
#         self.miso_logger.debug("Proposing to move to impossible state!")	    
#         raise Exception, "Proposing to move to impossible state!"
#     if abs(mh_ratio) == Inf:
#         self.miso_logger.debug("MH ratio is Inf!")
#         raise Exception, "MH ratio is Inf!"
#     return (exp(mh_ratio), curr_joint_score, proposed_joint_score)    

    

##
## Sampler scoring functions
##

# def log_score_joint_single_end(np.ndarray[DTYPE_t, ndim=1] reads,
#                                np.ndarray[DTYPE_t, ndim=1] assignments,
#                                np.ndarray[DTYPE_float_t, ndim=1] psi_vector,
#                                DTYPE_float_t log_score_psi_vector,
#                                int num_reads):
#     """
#     Return a log score for the joint distribution for single-end reads.

#     Parameters:
#     -----------

#     reads : array, array of reads
#     assignments : assignments of reads to isoforms
#     psi_vector : array, Psi vector in current state
#     log_score_psi_vector : float, the log score of Psi vector (computed
#     from Python)
#     num_reads : int, number of reads
#     """
#     # Get the logged Psi frag vector
#     # ....
#     # Score the read
#     if not self.paired_end:
# #            log_reads_prob = \
# #                sum(self.log_score_reads(reads, assignments, gene))
# #	    log_reads_prob = \
# #                sum(miso_scores.log_score_reads(reads,
# #                                                assignments,
# #                                                self.num_parts_per_isoform,
# #                                                self.iso_lens,
# #                                                self.num_reads,
# #                                                self.log_num_reads_possible_per_iso))
#         log_reads_prob = \
#             miso_scores.sum_log_score_reads(reads,
#                                             assignments,
#                                             self.num_parts_per_isoform,
#                                             self.iso_lens,
#                                             self.num_reads,
#                                             self.log_num_reads_possible_per_iso)
#         log_psi_frag = \
#             miso_scores.compute_log_psi_frag(psi_vector,
#                                              self.scaled_lens_single_end,
#                                              self.num_isoforms)
#     else:
#         raise Exception, "Paired-end not implemented!"
#         log_reads_prob = \
#             sum(self.log_score_paired_end_reads(reads, assignments, gene))
#         log_psi_frag = None
#     if not self.paired_end:
#         log_assignments_prob = \
#             miso_scores.sum_log_score_assignments(assignments,
#                                                   log_psi_frag,
#                                                   self.num_reads)
#     else:
#         raise Exception, "Paired-end not implemented!"
#         log_assignments_prob = \
#             sum(self.log_score_paired_end_assignment(assignments,
#                                                      psi_vector,
#                                                      gene))
#     # Score the Psi vector: keep this in Python for now
#     log_psi_prob = self.log_score_psi_vector(psi_vector, hyperparameters)
#     log_joint_score = log_reads_prob + log_assignments_prob + log_psi_prob
#     return log_joint_score


@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
def log_score_psi_vector(np.ndarray[DTYPE_float_t, ndim=1] psi_vector,
                         np.ndarray[DTYPE_float_t, ndim=1] hyperparameters):
    return stat_helpers.dirichlet_lnpdf(hyperparameters, psi_vector)


@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
cdef np.ndarray[DTYPE_float_t, ndim=1] \
  log_score_assignments(np.ndarray[DTYPE_t, ndim=1] isoform_nums,
                        np.ndarray[DTYPE_float_t, ndim=1] log_psi_frag_vector,
                        int num_reads):
    """
    Score an assignment of a set of reads given psi
    and a gene (i.e. a set of isoforms).
    """
    cdef np.ndarray[DTYPE_float_t, ndim=1] log_scores = \
      np.empty(num_reads, dtype=float)
    cdef DTYPE_float_t curr_log_psi_frag = 0.0
    cdef DTYPE_t curr_read = 0
    cdef DTYPE_t curr_iso_num = 0
    for curr_read in xrange(num_reads):
        curr_iso_num = isoform_nums[curr_read]
        # The score of an assignment to isoform i is the ith entry
        # is simply the Psi_Frag vector
        curr_log_psi_frag = log_psi_frag_vector[curr_iso_num]
        log_scores[curr_read] = curr_log_psi_frag 
    return log_scores

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
def py_log_score_assignments(np.ndarray[DTYPE_t, ndim=1] isoform_nums,
                             np.ndarray[DTYPE_float_t, ndim=1] log_psi_frag_vector,
                             int num_reads):
    return log_score_assignments(isoform_nums,
                                 log_psi_frag_vector,
                                 num_reads)


@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
def sum_log_score_assignments(np.ndarray[DTYPE_t, ndim=1] isoform_nums,
                              np.ndarray[DTYPE_float_t, ndim=1] log_psi_frag_vector,
                              int num_reads):
    """
    Score an assignment of a set of reads given psi
    and a gene (i.e. a set of isoforms).
    """
    cdef np.ndarray[DTYPE_float_t, ndim=1] assignment_scores = \
        np.empty(num_reads)
    cdef DTYPE_float_t sum_log_scores = 0.0
    cdef DTYPE_float_t curr_assignment_score = 0.0
    cdef DTYPE_t curr_read = 0
    # Get log score of assignments
    assignment_scores = log_score_assignments(isoform_nums,
                                              log_psi_frag_vector,
                                              num_reads)
    for curr_read in xrange(num_reads):
        curr_assignment_score = assignment_scores[curr_read]
        sum_log_scores += curr_assignment_score
    return sum_log_scores


@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
def compute_log_psi_frag(np.ndarray[DTYPE_float_t, ndim=1] psi_vector,
                         np.ndarray[DTYPE_t, ndim=1] scaled_lens,
                         int num_isoforms):
    """
    Compute log Psi frag from Psi vector.

    FOR SINGLE-END right now.
    """
    # Log psi frag vector computed from psi vector
    cdef np.ndarray[DTYPE_float_t, ndim=1] log_psi_frag = \
        np.empty(num_isoforms)
    # Isoform counter
    cdef DTYPE_t curr_isoform = 0
    for curr_isoform in xrange(num_isoforms):
        log_psi_frag[curr_isoform] = \
            log(psi_vector[curr_isoform]) + log(scaled_lens[curr_isoform])
    # Normalize scaled Psi values to sum to 1
    log_psi_frag = \
        log_psi_frag - my_logsumexp(log_psi_frag, num_isoforms)
    return log_psi_frag
    #curr_log_psi_frag = \
    #    np.log(curr_psi_vector) + np.log(self.scaled_lens_single_end)
    #curr_log_psi_frag = \
    #    curr_log_psi_frag - scipy.misc.logsumexp(curr_log_psi_frag)


@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
def sum_log_score_reads(np.ndarray[DTYPE_t, ndim=2] reads,
                        np.ndarray[DTYPE_t, ndim=1] isoform_nums,
                        np.ndarray[DTYPE_t, ndim=1] num_parts_per_isoform,
                        np.ndarray[DTYPE_t, ndim=1] iso_lens,
                        np.ndarray[double, ndim=1] log_num_reads_possible_per_iso,
                        np.int_t num_reads,
                        np.int_t read_len,
                        np.int_t overhang_len):
    """
    Returns the sum of vectors of scores computed by 'log_score_reads'.
    """
    cdef np.ndarray[DTYPE_float_t, ndim=1] vect_log_scores = \
      np.empty(num_reads, dtype=float)
    cdef DTYPE_float_t sum_scores = 0.0
    cdef DTYPE_t curr_read = 0
    # Call log score reads to get vector of scores
    vect_log_scores = log_score_reads(reads,
                                      isoform_nums,
                                      num_parts_per_isoform,
                                      iso_lens,
                                      log_num_reads_possible_per_iso,
                                      num_reads,
                                      read_len,
                                      overhang_len)
    for curr_read in xrange(num_reads):
        # If a score for any of the reads is -inf, then
        # the sum of the scores is -inf, so no point computing
        # the rest
        if vect_log_scores[curr_read] == (-1 * INFINITY):
            sum_scores = (-1 * INFINITY)
            break
        # Sum the scores
        sum_scores += vect_log_scores[curr_read]
    return sum_scores


# Define infinity
cdef extern from "math.h":
    float INFINITY

NEG_INFINITY = (-1 * INFINITY)

    
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
def log_score_reads(np.ndarray[DTYPE_t, ndim=2] reads,
                    np.ndarray[DTYPE_t, ndim=1] isoform_nums,
                    np.ndarray[DTYPE_t, ndim=1] num_parts_per_isoform,
                    np.ndarray[DTYPE_t, ndim=1] iso_lens,
                    np.ndarray[double, ndim=1] log_num_reads_possible_per_iso,
                    np.int_t num_reads,
                    np.int_t read_len,
                    np.int_t overhang_len):
    """
    Scores a set of reads given their isoform assignments.

    Parameters:
    -----------
    reads : 2-d array, representation of reads
    isoform_nums : 1-d np.array, assignment of each read to isoform. ith entry
                   is the assignment of ith read.
    num_parts_per_isoform : 1-d array, number of parts (exons) in each isoform
    iso_lens : 1-d array, lengths of each isoform
    num_reads : int, number of reads to process
    log_num_reads_possible_per_iso : 1-d array, the log'd number of reads
    possible in each isoform taking into account read length and the
    overhang length constraint.
    """
    cdef np.ndarray[DTYPE_float_t, ndim=1] log_prob_reads = \
      np.empty(num_reads, dtype=float)
    # Read counter
    cdef int curr_read = 0
    # Isoform counter
    cdef int curr_iso_num = 0
    for curr_read in xrange(num_reads):
        # For each isoform assignment, score its probability
        # Get the current isoform's number (0,...,K-1 for K isoforms)
        curr_iso_num = isoform_nums[curr_read]
        # Check if the read is consistent with isoform
        # if it isn't, record 0 probability
        if reads[curr_read, curr_iso_num] == 0:
            # Read consistent with isoform
            log_prob_reads[curr_read] = NEG_INFINITY
        else:
            # Uniform scoring: probability of read is:
            #    1/(number of possible reads from isoform)
            #  = 1/(iso_len - read_len + 1)
            #  = log[1/(iso_len - read_len + 1)]
            #  = log(1) - log(iso_len - read_len + 1)
            log_prob_reads[curr_read] = \
                log(1) - log_num_reads_possible_per_iso[curr_iso_num]
    return log_prob_reads


##
## Sampling functions
##
# Sample reassignments
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
cdef np.ndarray[DTYPE_t, ndim=1] \
  sample_reassignments(np.ndarray[DTYPE_t, ndim=2] reads,
                       np.ndarray[DTYPE_float_t, ndim=1] psi_vector,
                       np.ndarray[DTYPE_float_t, ndim=1] log_psi_frag_vector,
                       np.ndarray[DTYPE_float_t, ndim=1] log_num_reads_possible_per_iso,
                       np.ndarray[DTYPE_t, ndim=1] scaled_lens,
                       np.ndarray[DTYPE_t, ndim=1] iso_lens,
                       np.ndarray[DTYPE_t, ndim=1] num_parts_per_iso,
                       np.ndarray[DTYPE_t, ndim=1] iso_nums,
                       np.int_t num_reads,
                       np.int_t read_len,
                       np.int_t overhang_len):
    """
    Sample a reassignments of reads to isoforms.
    Note that this does not depend on the read's current assignment since
    we're already considering the possibility of 'reassigning' the read to
    its current assignment in the probability calculations.
    """
    cdef DTYPE_t num_isoforms = psi_vector.shape[0]
    # Initial probabilities of assignments given Psi vector
    cdef np.ndarray[DTYPE_float_t, ndim=1] log_assignment_probs = \
      np.empty(num_isoforms, dtype=float)
    # Initial probabilties of reads given assignments
    cdef np.ndarray[DTYPE_float_t, ndim=1] log_read_probs = \
      np.empty(num_reads, dtype=float)
    # Probabilities of reassigning current read to each of the isoforms
    cdef np.ndarray[DTYPE_float_t, ndim=1] reassignment_probs = \
      np.empty(num_isoforms, dtype=float)
    # Normalized reassignment probabilities
    cdef np.ndarray[DTYPE_float_t, ndim=1] norm_reassignment_probs = \
      np.empty(num_isoforms)
    # Array of new assignments to be returned
    cdef np.ndarray[DTYPE_t, ndim=1] new_assignments = \
      np.empty(num_reads, dtype=int)
    # The candidate assignment of current read
    cdef np.ndarray[np.int_t, ndim=1] cand_assignment = \
      np.empty(1, dtype=np.int)
    # Log probability of candidate assignment
    cdef DTYPE_float_t cand_assignment_log_prob
    # Array containing a single-read, the current read to be
    # considered
    cdef np.ndarray[np.int_t, ndim=2] curr_read_array = \
       np.zeros([2,2], dtype=np.int)
    # The sampled current read assignment
    cdef DTYPE_t curr_read_assignment = 0
    # Current isoform counter
    cdef DTYPE_t curr_isoform = 0
    # Current read counter
    cdef DTYPE_t curr_read = 0
    # First calculate the scores of all the current reads
    # given their isoform assignment
    log_read_probs = log_score_reads(reads,
                                     iso_nums,
                                     num_parts_per_iso,
                                     iso_lens,
                                     log_num_reads_possible_per_iso,
                                     num_reads,
                                     read_len,
                                     overhang_len)
    # Also calculate the scores of all current assignments
    log_assignment_probs = log_score_assignments(iso_nums,
                                                 log_psi_frag_vector,
                                                 num_reads)
    # For each read, compute the probability of reassigning it to
    # each of the isoforms and sample a new reassignment
    for curr_read in xrange(num_reads):
        # Copy the current assignment of read probability
        old_read_prob = log_read_probs[curr_read]
        # Copy the current assignment of read to isoform
        old_assignment = <DTYPE_t>iso_nums[curr_read]
        # Copy the current probability of assignment
        old_assignment_log_prob = log_assignment_probs[curr_read]
        # Compute the probability of assigning the current read
        # to each isoform
        for curr_isoform in xrange(num_isoforms):
            # Now consider reassigning this read to the current isoform
            iso_nums[curr_read] = <DTYPE_t>curr_isoform
            # Score this assignment of reads to isoforms
            cand_assignment[0] = curr_isoform
            # Compute probability of candidate assignment. This depends
            # only on the Psi Frag vectors:
            #    P(I(j,k) | PsiFrag)
            cand_assignment_log_prob = \
              <DTYPE_float_t>(log_score_assignments(cand_assignment,
                                                    log_psi_frag_vector,
                                                    1))
            # Compute the probability of the reads given the current
            # assignment. The only term that changes is the probability
            # of the current read, since we changed its assignment
            #    P(R | I)
            curr_read_array = reads[curr_read:curr_read+1]
            # Score probability of current read given candidate
            # assignment
            cand_read_log_prob = \
              <DTYPE_float_t>(log_score_reads(curr_read_array,
                                              cand_assignment,
                                              num_parts_per_iso,
                                              iso_lens,
                                              log_num_reads_possible_per_iso,
                                              1,
                                              read_len,
                                              overhang_len)[0])
            # Set the new probability of current read
            log_read_probs[curr_read] = cand_read_log_prob
            # Set the new probability of read's assignment
            log_assignment_probs[curr_read] = cand_assignment_log_prob
            # Now compute reassignment probabilities
            # Probability of assigning the read to this isoform
            # is the sum: log(P(reads | assignment)) + log(P(assignment | Psi))
            # P(log(reads | assignment) is the sum of the read scores
            # vector with the current read's reassignment
            reassignment_probs[curr_isoform] = \
              (matrix_utils.sum_array(log_assignment_probs, num_reads) + \
               matrix_utils.sum_array(log_read_probs, num_reads))
            # Copy the old assignment of the read to the isoform
            iso_nums[curr_read] = old_assignment
            # Copy the old assignment probability
            log_assignment_probs[curr_read] = old_assignment_log_prob
            # Copy the old probability of read given the isoform
            log_read_probs[curr_read] = old_read_prob
        # Normalize the reassignment probabilities
        norm_reassignment_probs = \
          norm_log_probs(reassignment_probs, num_isoforms)
        curr_read_assignment = \
          sample_from_multinomial(norm_reassignment_probs, 1,
                                  curr_read_assignment)
        new_assignments[curr_read] = curr_read_assignment
    return new_assignments


# Sample reassignments
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
def py_sample_reassignments(np.ndarray[DTYPE_t, ndim=2] reads,
                            np.ndarray[DTYPE_float_t, ndim=1] psi_vector,
                            np.ndarray[DTYPE_float_t, ndim=1] log_psi_frag_vector,
                            np.ndarray[DTYPE_float_t, ndim=1] log_num_reads_possible_per_iso,
                            np.ndarray[DTYPE_t, ndim=1] scaled_lens,
                            np.ndarray[DTYPE_t, ndim=1] iso_lens,
                            np.ndarray[DTYPE_t, ndim=1] num_parts_per_iso,
                            np.ndarray[DTYPE_t, ndim=1] iso_nums,
                            np.int_t num_reads,
                            np.int_t read_len,
                            np.int_t overhang_len):
    return sample_reassignments(reads,
                                psi_vector,
                                log_psi_frag_vector,
                                log_num_reads_possible_per_iso,
                                scaled_lens,
                                iso_lens,
                                num_parts_per_iso,
                                iso_nums,
                                num_reads,
                                read_len,
                                overhang_len)



cdef np.ndarray[DTYPE_float_t, ndim=1] \
     norm_log_probs(np.ndarray[DTYPE_float_t, ndim=1] log_probs,
                    int vector_len):
    """
    Normalize log probabilities to sum to 1. Returns an UNLOGGED
    probability!
    """
    # Normalizing factor
    cdef DTYPE_float_t norm_factor = my_logsumexp(log_probs, vector_len)
    # Normalized probabilities (UNLOGGED)
    cdef np.ndarray[DTYPE_float_t, ndim=1] norm_probs = \
      np.empty(vector_len, dtype=float)
    for curr_entry in xrange(vector_len):
        # If the current log probability is -inf, then
        # record it as 0 (unlogged probability)
        if log_probs[curr_entry] == NEG_INFINITY:
            norm_prob = 0.0
        else:
            # Otherwise, normalize by normalizing factor
            norm_prob = exp(log_probs[curr_entry] - norm_factor)
        # Record unlogged probability
        norm_probs[curr_entry] = norm_prob
    return norm_probs
        

cdef np.ndarray[DTYPE_float_t, ndim=1] \
     sample_from_multinomial(np.ndarray[DTYPE_float_t, ndim=1] probs,
                             int N,
                             np.ndarray[DTYPE_float_t, ndim=1] samples):
    """
    Sample one element from multinomial probabilities vector.

    Assumes that the probabilities sum to 1.

    Parameters:
    -----------

    probs : array, vector of probabilities
    N : int, number of samples to draw
    """
    cdef int num_elts = probs.shape[0]
    # The samples: indices into probs
    #cdef np.ndarray[DTYPE_float_t, ndim=1] samples = \
    #  np.empty(N, dtype=float)
    # Current random samples
    cdef int random_sample = 0
    # Counters over number of samples and number of
    # elements in probability vector
    cdef int curr_sample = 0
    cdef int curr_elt = 0
    cdef DTYPE_float_t rand_val# = rand() / MY_MAX_INT
    # Get cumulative sum of probability vector
    cdef np.ndarray[DTYPE_float_t, ndim=1] cumsum = \
      stat_helpers.my_cumsum(probs)
    for curr_sample in xrange(N):
        # Draw random number
        rand_val = (rand() % MY_MAX_INT) / MY_MAX_INT
        for curr_elt in xrange(num_elts):
            # If the current cumulative sum is greater than the
            # random number, assign it the index
            if cumsum[curr_elt] >= rand_val:
                random_sample = curr_elt
                break
        samples[curr_sample] = random_sample
    return samples

def py_sample_from_multinomial(np.ndarray[DTYPE_float_t, ndim=1] probs,
                               int N,
                               np.ndarray[DTYPE_float_t, ndim=1] samples):
    return sample_from_multinomial(probs, N, samples)


cpdef double[:] \
     pure_sample_from_multinomial(double[:] probs,
                                  int N,
                                  double[:] samples):
    """
    Sample one element from multinomial probabilities vector.

    Assumes that the probabilities sum to 1.

    Parameters:
    -----------

    probs : array, vector of probabilities
    N : int, number of samples to draw
    """
    cdef int num_elts = probs.shape[0]
    # Current random samples
    cdef int random_sample = 0
    # Counters over number of samples and number of
    # elements in probability vector
    cdef int curr_sample = 0
    cdef int curr_elt = 0
    cdef double rand_val# = rand() / MY_MAX_INT
    # Get cumulative sum of probability vector
    cdef double[:] cumsum = stat_helpers.pure_my_cumsum(probs)
    for curr_sample in xrange(N):
        # Draw random number
        rand_val = (rand() % MY_MAX_INT) / MY_MAX_INT
        for curr_elt in xrange(num_elts):
            # If the current cumulative sum is greater than the
            # random number, assign it the index
            if cumsum[curr_elt] >= rand_val:
                random_sample = curr_elt
                break
        samples[curr_sample] = random_sample
    return samples



cpdef np.ndarray[DTYPE_t, ndim=1] \
  init_assignments(np.ndarray[DTYPE_t, ndim=2] reads,
                   int num_reads,
                   int num_isoforms):
    """
    Initialize assignments of reads to isoforms.

    NOTE: This assumes that the reads that are NOT consistent
    with all the isoforms have been thrown out. If they are
    present, they will be skipped
    """
    # Assignments array to return
    cdef np.ndarray[DTYPE_t, ndim=1] assignments = \
      np.empty(num_reads, dtype=int)
    cdef int curr_read = 0
    cdef int curr_iso = 0
    for curr_read in xrange(num_reads):
        for curr_iso in xrange(num_isoforms):
            # Assign read to the first isoform it is consistent
            # with. 
            if reads[curr_read, curr_iso] == 1:
                assignments[curr_read] = curr_iso
                break
    return assignments


cpdef int[:] \
  pure_init_assignments(int[:, :] reads,
                        int num_reads,
                        int num_isoforms):
    """
    Initialize assignments of reads to isoforms.

    NOTE: This assumes that the reads that are NOT consistent
    with all the isoforms have been thrown out. If they are
    present, they will be skipped
    """
    # Assignments array to return
    cdef int[:] assignments = \
      cvarray(shape=(num_reads,), itemsize=sizeof(int), format="i")
    cdef int curr_read = 0
    cdef int curr_iso = 0
    for curr_read in xrange(num_reads):
        for curr_iso in xrange(num_isoforms):
            # Assign read to the first isoform it is consistent
            # with. 
            if reads[curr_read, curr_iso] == 1:
                assignments[curr_read] = curr_iso
                break
    return assignments
 
        

#     def propose_norm_drift_psi_alpha(self, alpha_vector):
#         if len(alpha_vector) == 1:
#             alpha_vector = alpha_vector[0]
# #            print "proposing from normal with mean: ", alpha_vector, " exp: ", exp(alpha_vector)
#             alpha_next = [normal(alpha_vector, self.params['sigma_proposal'])]
# #            print "got alpha_next: ", alpha_next, " exp: ", exp(alpha_next)
#             new_psi = logit_inv([alpha_next[0]])[0]
#             new_psi_vector = [new_psi, 1-new_psi]
#         else:
#             alpha_next = multivariate_normal(alpha_vector, self.params['sigma_proposal'])
#             new_psi = logit_inv(alpha_next)
#             new_psi_vector = concatenate((new_psi, array([1-sum(new_psi)])))
#         return (new_psi_vector, alpha_next)





