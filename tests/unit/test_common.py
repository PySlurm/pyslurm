#########################################################################
# test_common.py - common utility tests
#########################################################################
# Copyright (C) 2023 Toni Harzendorf <toni.harzendorf@gmail.com>
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
"""test_common.py - Test the most commonly used helper functions."""

import pyslurm
import pytest
import datetime
from pyslurm import Job, JobSubmitDescription, Node
from pyslurm.core.common.ctime import (
    timestr_to_mins,
    timestr_to_secs,
    mins_to_timestr,
    secs_to_timestr,
    date_to_timestamp,
    timestamp_to_date,
)
from pyslurm.core.common.uint import (
    u8,
    u16,
    u32,
    u64,
    u8_parse,
    u16_parse,
    u32_parse,
    u64_parse,
)
from pyslurm.core.common import (
    uid_to_name,
    gid_to_name,
    user_to_uid,
    group_to_gid,
    expand_range_str,
    humanize,
    dehumanize,
    signal_to_num,
    cpubind_to_num,
    nodelist_from_range_str,
    nodelist_to_range_str,
    _sum_prop,
)
from pyslurm.core.common import cstr


class TestTypes:

    def test_strings(self):
        n = Node()

        n.name = "Testing fmalloc string routines."
        assert n.name == "Testing fmalloc string routines."

        n.name = None
        assert n.name is None

        # Everything after a \0 will be cut off
        n.name = "test1\0test2"
        assert n.name == "test1"

        n.name = "\0"
        assert n.name is None

    def test_lists(self):
        n = Node()
        input_as_list = ["test1", "test2", "test3", "test4"]
        input_as_str = ",".join(input_as_list)
        
        n.available_features = input_as_list
        assert n.available_features == input_as_list

        n.available_features = input_as_str
        assert n.available_features == input_as_list

        n.available_features = []
        assert n.available_features == []

        n.available_features = ""
        assert n.available_features == []

        n.available_features = None
        assert n.available_features == []

    def test_str_to_dict(self):
        expected_dict = {"key1": "value1", "key2": "value2"}
        input_str = "key1=value1,key2=value2"
        assert cstr.to_dict(input_str) == expected_dict 
        assert cstr.to_dict("") == {}

    def test_dict_to_str(self):
        input_dict = {"key1": "value1", "key2": "value2"}
        expected_str = "key1=value1,key2=value2"
        assert cstr.dict_to_str(input_dict) == expected_str

        input_dict = {"key1": "value1", "key2": "value2"}
        expected_str = "key1=value1,key2=value2"
        assert cstr.dict_to_str(input_dict) == expected_str

        expected_str = "key1-value1:key2-value2"
        assert cstr.dict_to_str(input_dict, delim1=":", delim2="-") == expected_str

        input_dict = {"key1=": "value1", "key2": "value2"}
        expected_str = "key1=value1,key2=value2"
        with pytest.raises(ValueError,
                           match=r"Key or Value cannot contain either*"): 
            assert cstr.dict_to_str(input_dict) == expected_str

        expected_str = "key1=value1,key2=value2"
        assert cstr.dict_to_str(expected_str) == expected_str
            
        assert cstr.dict_to_str({}) == None
        assert cstr.dict_to_str("") == None

    def test_dict_to_gres_str(self):
        input_dict = {"gpu:tesla": 3}
        expected_str = "gres:gpu:tesla:3"
        assert cstr.from_gres_dict(input_dict) == expected_str
        assert cstr.from_gres_dict(expected_str) == expected_str

        input_dict = {"gpu": 3}
        expected_str = "gres:gpu:3"
        assert cstr.from_gres_dict(input_dict) == expected_str
        assert cstr.from_gres_dict(expected_str) == expected_str

    def test_str_to_gres_dict(self):
        assert True

    def _uint_impl(self, func_set, func_get, typ):
        val = func_set(2**typ-2)
        assert func_get(val) == None

        val = func_set(None)
        assert func_get(val) == None

        val = func_set(str(2**typ-2))
        assert func_get(val) == None

        val = func_set("unlimited", inf=True)
        assert func_get(val) == "unlimited"

        val = func_set(0)
        assert func_get(val) == None

        val = func_set(0, zero_is_noval=False)
        assert func_get(val, zero_is_noval=False) == 0

        with pytest.raises(TypeError,
                           match="an integer is required"): 
            val = func_set("unlimited")

        with pytest.raises(OverflowError,
                           match=r"can't convert negative value to*"): 
            val = func_set(-1)

        with pytest.raises(OverflowError,
                           match=r"value too large to convert to*|"
                                  "Python int too large*"): 
            val = func_set(2**typ)

    def test_u8(self):
        self._uint_impl(u8, u8_parse, 8)

    def test_u16(self):
        self._uint_impl(u16, u16_parse, 16)

    def test_u32(self):
        self._uint_impl(u32, u32_parse, 32)

    def test_u64(self):
        self._uint_impl(u64, u64_parse, 64)

#   def _uint_bool_impl(self, arg):
#       js = JobSubmitDescription()

#       setattr(js, arg, True)
#       assert getattr(js, arg) == True

#       setattr(js, arg, False)
#       assert getattr(js, arg) == False

#       # Set to true again to make sure toggling actually works.
#       setattr(js, arg, True)
#       assert getattr(js, arg) == True

#       setattr(js, arg, None)
#       assert getattr(js, arg) == False

#   def test_u8_bool(self):
#       self._uint_bool_impl("overcommit")

#   def test_u16_bool(self):
#       self._uint_bool_impl("requires_contiguous_nodes")

#   def test_u64_bool_flag(self):
#       self._uint_bool_impl("kill_on_invalid_dependency")


class TestTime:

    def test_parse_minutes(self):
        mins = 60
        mins_str = "01:00:00"

        assert timestr_to_mins(mins_str) == mins
        assert timestr_to_mins("unlimited") == 2**32-1 
        assert timestr_to_mins(None) == 2**32-2

        assert mins_to_timestr(mins) == mins_str
        assert mins_to_timestr(2**32-1) == "unlimited"
        assert mins_to_timestr(2**32-2) == None
        assert mins_to_timestr(0) == None 

        with pytest.raises(ValueError,
                match="Invalid Time Specification: invalid_val."):
            timestr_to_mins("invalid_val")

    def test_parse_seconds(self):
        secs = 3600
        secs_str = "01:00:00"

        assert timestr_to_secs(secs_str) == secs
        assert timestr_to_secs("unlimited") == 2**32-1 
        assert timestr_to_secs(None) == 2**32-2

        assert secs_to_timestr(secs) == secs_str
        assert secs_to_timestr(2**32-1) == "unlimited"
        assert secs_to_timestr(2**32-2) == None
        assert secs_to_timestr(0) == None 

        with pytest.raises(ValueError,
                match="Invalid Time Specification: invalid_val."):
            timestr_to_secs("invalid_val")

    def test_parse_date(self):
        timestamp = 1667941697
        date = "2022-11-08T21:08:17" 
        datetime_date = datetime.datetime(2022, 11, 8, 21, 8, 17)

        # Converting date str to timestamp with the slurm API functions may
        # not yield the expected timestamp above due to using local time zone
        assert date_to_timestamp(date) == timestamp
        assert date_to_timestamp(timestamp) == timestamp
        assert date_to_timestamp(datetime_date) == timestamp

        assert timestamp_to_date(timestamp) == date
        assert timestamp_to_date(0) == None
        assert timestamp_to_date(2**32-1) == None
        assert timestamp_to_date(2**32-2) == None

        with pytest.raises(ValueError,
                match="Invalid Time Specification: 2022-11-08T21"):
            date_to_timestamp("2022-11-08T21")

class TestMiscUtil:

    def test_parse_uid(self):
        name = uid_to_name(0)
        assert name == "root"

        lookup = {0: "root"}
        name = uid_to_name(0, lookup=lookup) 
        assert name == "root"

        uid = user_to_uid("root")
        assert uid == 0

        with pytest.raises(KeyError):
            name = uid_to_name(2**32-5)

        with pytest.raises(KeyError):
            name = user_to_uid("invalid_user")

    def test_parse_gid(self):
        name = gid_to_name(0)
        assert name == "root"

        lookup = {0: "root"}
        name = gid_to_name(0, lookup=lookup) 
        assert name == "root"

        gid = group_to_gid("root")
        assert gid == 0

        with pytest.raises(KeyError):
            name = gid_to_name(2**32-5)

        with pytest.raises(KeyError):
            name = group_to_gid("invalid_group")

    def test_expand_range_str(self):
        r = expand_range_str("1-5,6,7,10-11")
        assert r == [1, 2, 3, 4, 5, 6, 7, 10, 11]

    def test_humanize(self):
        val = humanize(1024)
        assert val == "1.0G" 

        val = humanize(2**20)
        assert val == "1.0T"
        
        val = humanize(800)
        assert val == "800.0M"

        val = humanize("unlimited")
        assert val == "unlimited"

        val = humanize(None)
        assert val == None

        with pytest.raises(ValueError):
            val = humanize("invalid_val")

    def test_dehumanize(self):
        # Note: default target unit for dehumanize is "M".
        val = dehumanize(1024)
        assert val == 1024

        val = dehumanize("2M") 
        assert val == 2

        val = dehumanize("10G") 
        assert val == 10240

        val = dehumanize("9.6G") 
        assert val == round(1024*9.6)

        val = dehumanize("10T") 
        assert val == 10*(2**20)

        val = dehumanize("10T", target="G") 
        assert val == 10*(2**10)

        with pytest.raises(ValueError,
                match="Invalid value specified: 10L"):
           val = dehumanize("10L")

        with pytest.raises(ValueError,
                match="could not convert string to float: 'invalid_val'"):
           val = dehumanize("invalid_valM")
        
    def test_signal_to_num(self):
       sig = signal_to_num("SIGKILL")
       assert sig == 9

       sig = signal_to_num(7)
       assert sig == 7

       with pytest.raises(ValueError):
           sig = signal_to_num("invalid_sig")

    def test_nodelist_from_range_str(self):
        nodelist = ["node001", "node007", "node008", "node009"]
        nodelist_str = ",".join(nodelist)
        assert nodelist == nodelist_from_range_str("node[001,007-009]")
        assert nodelist_from_range_str("node[001,007:009]") == []

    def test_nodelist_to_range_str(self):
        nodelist = ["node001", "node007", "node008", "node009"]
        nodelist_str = ",".join(nodelist)
        assert "node[001,007-009]" == nodelist_to_range_str(nodelist)
        assert "node[001,007-009]" == nodelist_to_range_str(nodelist_str)

    def test_summarize_property(self):
        class TestObject:
            @property
            def memory(self):
                return 10240

            @property
            def cpus(self):
                return None

        object_dict = {i: TestObject() for i in range(10)}

        expected = 10240 * 10
        assert _sum_prop(object_dict, TestObject.memory) == expected

        expected = 0
        assert _sum_prop(object_dict, TestObject.cpus) == 0
