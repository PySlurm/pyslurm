/*****************************************************************************\
 *  job_resources.h - functions to manage data structure identifying specific
 *  CPUs allocated to a job, step or partition
 *****************************************************************************
 *  Copyright (C) 2008 Lawrence Livermore National Security.
 *  Written by Morris Jette <jette1@llnl.gov>.
 *  CODE-OCEC-09-009. All rights reserved.
 *
 *  This file is part of Slurm, a resource management program.
 *  For details, see <https://slurm.schedmd.com/>.
 *  Please also read the included file: DISCLAIMER.
 *
 *  Slurm is free software; you can redistribute it and/or modify it under
 *  the terms of the GNU General Public License as published by the Free
 *  Software Foundation; either version 2 of the License, or (at your option)
 *  any later version.
 *
 *  In addition, as a special exception, the copyright holders give permission
 *  to link the code of portions of this program with the OpenSSL library under
 *  certain conditions as described in each individual source file, and
 *  distribute linked combinations including the two. You must obey the GNU
 *  General Public License in all respects for all of the code used other than
 *  OpenSSL. If you modify file(s) with this exception, you may extend this
 *  exception to your version of the file(s), but you are not obligated to do
 *  so. If you do not wish to do so, delete this exception statement from your
 *  version.  If you delete this exception statement from all source files in
 *  the program, then also delete it here.
 *
 *  Slurm is distributed in the hope that it will be useful, but WITHOUT ANY
 *  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 *  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 *  details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with Slurm; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA.
\*****************************************************************************/

#ifndef _JOB_RESOURCES_H
#define _JOB_RESOURCES_H

#include <inttypes.h>

/* struct job_resources defines exactly which resources are allocated
 *  to a job, step, partition, etc.
 *
 * core_bitmap      - Bitmap of allocated cores for all nodes and sockets.
 *            The bitmap reflects allocated resources only on the
 *            allocated nodes, not the full system resources.
 * core_bitmap_used - Bitmap of cores allocated to job steps (see above)
 * cores_per_socket - Count of cores per socket on this node, build by
 *            build_job_resources() and ensures consistent
 *            interpretation of core_bitmap
 * cpus         - Count of desired/allocated CPUs per node for job/step
 * cpus_used        - For a job, count of CPUs per node used by job steps
 * cpu_array_cnt    - Count of elements in cpu_array_* below
 * cpu_array_value  - Count of allocated CPUs per node for job
 * cpu_array_reps   - Number of consecutive nodes on which cpu_array_value
 *            is duplicated. See NOTES below.
 * memory_allocated - MB per node reserved for the job or step
 * memory_used      - MB per node of memory consumed by job steps
 * nhosts       - Number of nodes in the allocation.  On a
 *                        bluegene machine this represents the number
 *                        of midplanes used.  This should always be
 *                        the number of bits set in node_bitmap.
 * node_bitmap      - Bitmap of nodes allocated to the job. Unlike the
 *            node_bitmap in slurmctld's job record, the bits
 *            here do NOT get cleared as the job completes on a
 *            node
 * node_req     - NODE_CR_RESERVED|NODE_CR_ONE_ROW|NODE_CR_AVAILABLE
 * nodes        - Names of nodes in original job allocation
 * ncpus        - Number of processors in the allocation
 * sock_core_rep_count  - How many consecutive nodes that sockets_per_node
 *            and cores_per_socket apply to, build by
 *            build_job_resources() and ensures consistent
 *            interpretation of core_bitmap
 * sockets_per_node - Count of sockets on this node, build by
 *            build_job_resources() and ensures consistent
 *            interpretation of core_bitmap
 * whole_node       - Job allocated full node (used only by select/cons_res)
 *
 * NOTES:
 * cpu_array_* contains the same information as "cpus", but in a more compact
 * format. For example if cpus = {4, 4, 2, 2, 2, 2, 2, 2} then cpu_array_cnt=2
 * cpu_array_value = {4, 2} and cpu_array_reps = {2, 6}. We do not need to
 * save/restore these values, but generate them by calling
 * build_job_resources_cpu_array()
 *
 * Sample layout of core_bitmap:
 *   |               Node_0              |               Node_1              |
 *   |      Sock_0     |      Sock_1     |      Sock_0     |      Sock_1     |
 *   | Core_0 | Core_1 | Core_0 | Core_1 | Core_0 | Core_1 | Core_0 | Core_1 |
 *   | Bit_0  | Bit_1  | Bit_2  | Bit_3  | Bit_4  | Bit_5  | Bit_6  | Bit_7  |
 *
 * If a job changes size (reliquishes nodes), the node_bitmap will remain
 * unchanged, but cpus, cpus_used, cpus_array_*, and memory_used will be 
 * updated (e.g. cpus and mem_used on that node cleared).
 */
struct job_resources {
    bitstr_t *core_bitmap;
    bitstr_t *core_bitmap_used;
    uint32_t  cpu_array_cnt;
    uint16_t *cpu_array_value;
    uint32_t *cpu_array_reps;
    uint16_t *cpus;
    uint16_t *cpus_used;
    uint16_t *cores_per_socket;
    uint64_t *memory_allocated;
    uint64_t *memory_used;
    uint32_t  nhosts;
    bitstr_t *node_bitmap;
    uint32_t  node_req;
    char     *nodes;
    uint32_t  ncpus;
    uint32_t *sock_core_rep_count;
    uint16_t *sockets_per_node;
    uint8_t   whole_node;
};

#endif /* !_JOB_RESOURCES_H */
