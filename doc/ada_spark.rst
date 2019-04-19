About SPARK integration
=======================

.. contents::

General principles of SPARK
---------------------------

.. highlight:: vhdl

SPARK usage in EwoK
-------------------

EwoK uses SPARK in the modules requiring formal validation and proofs.

Here is an example of such usage::

   function ipc_is_granted
      (from    : in t_real_task_id;
       to      : in t_real_task_id)
       return boolean
          with
             Global         => (Input => ewok.perm_auto.com_ipc_perm),
             Post           => (if (from = to) then ipc_is_granted'Result = false),
             Contract_Cases => (ewok.perm_auto.com_ipc_perm(from,to) => ipc_is_granted'Result,
                                others                               => not ipc_is_granted'Result);

This specification uses various SPARK properties:

   * Global usage declaration, which allows to specify that the function is
     using a global variable of the ewok.perm_auto package as read only.
   * Postcondition specification, requiring that for the specific use case
     where from and to are equal, the result of the function must be false,
     whatever the table content is.
   * A contract case, that describes the contract of the function as a fixed
     length list of possible values. This list is the exhaustive list of the
     possible results.

Impact of SPARK
---------------

Spark helps to prove the absence of RTE (Run Time Errors) on the blocks of
code that has been correctly proven. We also use it to validate some specific
security-oriented behaviors.

A typical example is to prove that the kernel never maps a memory region which
can be both writeable and executable (aka W^X proof).

For this, we use ghost functions and preconditions. The ghost function checks
the wanted properties, the precondition is checked at build time by the prover.
If the prover can't prove it at build time (e.g. when inputs depend on dynamic
content, lazy checks, etc.) the prover refuses to validate the precondition.

Here is the ghost function checking the W^X conditions on the STM32 MPU::

   -- Only used by SPARK prover
   function region_not_rwx(region : t_region_config) return boolean
       is (region.xn = true or region.access_perm = REGION_AP_RO_RO or
           region.access_perm = REGION_AP_NO_NO)
       with ghost;


EwoK proofs
^^^^^^^^^^^

The current state of the EwoK proof is the following, regularly updated as we
include some new proofs in the EwoK source code.

.. include:: ada_proof.rst
   :start-line: 3
