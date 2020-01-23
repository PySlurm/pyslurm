from __future__ import absolute_import, unicode_literals

import pyslurm
import subprocess
from nose.tools import assert_equals, assert_true
from socket import gethostname
import datetime

def njobs_sacct_jobs(start, end):
    sacct = subprocess.Popen(['sacct','-S',start,'-E',end,'-n','-X','-a'],stdout=subprocess.PIPE,stderr=None).communicate()
    return len(sacct[0].splitlines())

def njobs_sacct_jobs_byuser(start, end, username):
    sacct = subprocess.Popen(['sacct','-S',start,'-E',end,'-n','-X','-u',username],stdout=subprocess.PIPE,stderr=None).communicate()
    return len(sacct[0].splitlines())

def njobs_slurmdb_jobs_get(start,end):
    jobs = pyslurm.slurmdb_jobs().get(starttime=start.encode('utf-8'), endtime=end.encode('utf-8'))
    return len(jobs)

def njobs_slurmdb_jobs_get_byuid(start,end,uid):
    print(uid)
    jobs = pyslurm.slurmdb_jobs().get(starttime=start.encode('utf-8'), endtime=end.encode('utf-8'),userids=[uid])
    print('njobs by py slumr {}'.format(len(jobs)))
    return len(jobs)

def get_user():
    import pwd
    users = subprocess.Popen(['squeue', '-O', 'username', '-h'],stdout=subprocess.PIPE,stderr=None).communicate()
    for username in users[0].splitlines():
        print(username.decode())
        uid = pwd.getpwnam("{}".format(username.strip().decode()))
        yield username.strip().decode(),uid.pw_uid

    

def test_slurmdb_jobs_get():
    starttime = (datetime.datetime.now()-datetime.timedelta(days=2)).strftime("%Y-%m-%dT00:00:00")
    endtime = (datetime.datetime.now()-datetime.timedelta(days=1)).strftime("%Y-%m-%dT00:00:00")
    njobs_pyslurm = njobs_slurmdb_jobs_get(starttime,endtime)
    njobs_sacct = njobs_sacct_jobs(starttime,endtime)
    assert_equals(njobs_pyslurm,njobs_sacct)

def test_slurmdb_jobs_get_byuser():
    userlist = list(get_user())
    for user in userlist[:10]:
        starttime = (datetime.datetime.now()-datetime.timedelta(days=2)).strftime("%Y-%m-%dT00:00:00")
        endtime = (datetime.datetime.now()-datetime.timedelta(days=1)).strftime("%Y-%m-%dT00:00:00")
        njobs_pyslurm = njobs_slurmdb_jobs_get_byuid(starttime,endtime,int(user[1])) 
        njobs_sacct = njobs_sacct_jobs_byuser(starttime,endtime,user[0])
        print('njobs by sacct {}'.format(njobs_sacct))
        assert_equals(njobs_pyslurm,njobs_sacct)
    

