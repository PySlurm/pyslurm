#########################################################################
# error.pyx - pyslurm db specific errors
#########################################################################
# Copyright (C) 2025 Toni Harzendorf <toni.harzendorf@gmail.com>
#
# This file is part of PySlurm
#
# PySlurm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# PySlurm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with PySlurm; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# cython: c_string_type=unicode, c_string_encoding=default
# cython: language_level=3

from pyslurm.core.error import RPCError, slurm_errno, verify_rpc
from pyslurm.db.util cimport SlurmList, SlurmListItem
import re


# The response involving assoc modification and deletions is a string that can
# be in the following form:
#
# C = X         A = X       U = X       P = X
#
# And we have to parse this stuff... The Partition (P) is optional
assoc_str_pattern = re.compile(r'(\w)\s*=\s*(\w+)')


class AssociationChangeInfo:

    def __init__(self, user, cluster, account, partition=None):
        self.user = user
        self.cluster = cluster
        self.account = account
        self.partition = partition
        self.running_jobs = []


class JobsRunningError(RPCError):

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.associations = []

    @staticmethod
    def from_response(SlurmList response, rc):
        running_jobs = parse_running_job_errors(response)
        err = JobsRunningError(errno=rc)
        err.associations = list(running_jobs.values())
        return err


class DefaultAccountError(RPCError):

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.associations = []

    @staticmethod
    def from_response(SlurmList response, rc):
        err = DefaultAccountError(errno=rc)
        err.associations = parse_default_account_errors(response)
        return err


def get_responses(SlurmList response):
    cdef SlurmListItem response_ptr

    #TODO: check also for count?
    if response.is_null:
        return []

    for response_ptr in response:
        response_str = response_ptr.to_str()
        if response_str:
            yield response_str


def parse_assoc_str(value):
    matches = assoc_str_pattern.findall(value)
    return dict(matches)


def get_assoc_response(SlurmList response):
    for resp in get_responses(response):
        yield parse_assoc_str(resp)


def parse_default_account_errors(SlurmList response):
    assocs = []
    for item in get_assoc_response(response):
        info = AssociationChangeInfo(
            cluster = item["C"],
            account = item["A"],
            user = item["U"],
        )
        assoc_str = f"{info.cluster}-{info.account}-{info.user}"

        if len(item) > 3:
            info.partition = item["P"]
            assoc_str = f"{assoc_str}-{info.partition}"

        assocs.append(info)

    return assocs


def parse_basic_response(SlurmList response):
    return list(get_responses(response))


def parse_running_job_errors(SlurmList response):
    cdef SlurmListItem response_ptr

    running_jobs_for_assoc = {}
    for response_ptr in response:
        response_str = response_ptr.to_str()
        if not response_str:
            continue

        # The response is a string in the following form:
        # JobId = X       C = X         A = X       U = X       P = X
        #
        # And we have to parse this stuff... The Partition (P) is optional
        resp = response_str.rstrip().lstrip()
        splitted = resp.split("  ")
        values = []
        for item in splitted:
            if not item:
                continue

            key, value = item.split("=")
            values.append(value.strip())

        job_id = int(values[0])
        cluster = values[1]
        account = values[2]
        user = values[3]
        partition = None
        assoc_str = f"{cluster}-{account}-{user}"

        if len(values) > 4:
            partition = values[4]
            assoc_str = f"{assoc_str}-{partition}"

        if assoc_str not in running_jobs_for_assoc:
            info = AssociationChangeInfo(
                user = user,
                cluster = cluster,
                account = account,
                partition = partition,
            )
            running_jobs_for_assoc[assoc_str] = info

        running_jobs_for_assoc[assoc_str].running_jobs.append(job_id)

    return running_jobs_for_assoc
